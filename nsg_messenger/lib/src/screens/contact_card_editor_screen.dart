import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../contact_card/contact_card_view.dart';
import '../contact_card/vcard.dart';
import '../i18n/generated/nsg_l10n.dart';
import '../messages/attachments/attachment_picker.dart';
import '../messenger_runtime.dart';

// Chatista Glass токены (docs/design/chatista-glass-design-prompt.md).
const _bg = Color(0xFF1F1A15);
const _fg = Color(0xF5FFFCF8);
const _fgMuted = Color(0xB8FFFCF8);
const _fgDim = Color(0x80FFFCF8);
const _label = Color(0x99FFFCF8);
const _card = Color(0x14FFFFFF);
const _onAccent = Color(0xFF1A0F1A);

/// Пресеты градиентов редактора (тёплая палитра Chatista Glass +
/// несколько холодных; пары start→end '#RRGGBB').
const List<(String, String)> _gradientPresets = [
  ('#E89A55', '#1F1A15'), // sunset — фирменный
  ('#C96F4A', '#2A1A2E'), // терракота
  ('#8A5FBF', '#1A1030'), // фиолет
  ('#3E7CB1', '#101B2E'), // океан
  ('#3F8F6B', '#0F241C'), // лес
  ('#B93A5B', '#28101C'), // вино
  ('#5B5F97', '#14152B'), // индиго
  ('#8C8377', '#181512'), // графит
];

/// **TASK52 итер.1**: редактор личной визитки с live-превью.
///
/// Кастомизация в рамках шаблонов (photo | gradient | monogram):
/// пресеты градиентов, начертание имени, цвет имени (авто = автоконтраст),
/// фото-фон через существующий upload pipeline (TASK19). Поля «о себе» —
/// с per-field видимостью (все / только контакты).
class ContactCardEditorScreen extends StatefulWidget {
  const ContactCardEditorScreen({super.key});

  @override
  State<ContactCardEditorScreen> createState() =>
      _ContactCardEditorScreenState();
}

class _ContactCardEditorScreenState extends State<ContactCardEditorScreen> {
  bool _loading = true;
  bool _saving = false;
  bool _uploading = false;
  bool _exists = false; // есть ли карточка на сервере (для «удалить»)
  Object? _error;

  // Черновик стиля.
  String _template = 'gradient';
  String? _backgroundMxc;
  String _gradientStart = _gradientPresets.first.$1;
  String _gradientEnd = _gradientPresets.first.$2;
  String _fontStyle = 'classic';
  String? _nameColor; // null = автоконтраст

  final _aboutCtl = TextEditingController();
  final _jobCtl = TextEditingController();
  final _companyCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _websiteCtl = TextEditingController();
  final Set<String> _contactsOnly = {};

  // **TASK64**: языковые версии текстовых полей (about/должность/
  // компания). null = основной профиль (сама визитка). Управление
  // версиями (дефолт/удаление) — в редакторе профиля; здесь только
  // заполнение. Черновики per-locale, чтобы переключение не теряло ввод.
  List<ProfileTranslation> _translations = const [];
  String? _fieldsLocale;
  final Map<String?, List<String>> _fieldDrafts = {};

  static const Map<String, String> _localeNames = {
    'ru': 'Русский',
    'en': 'English',
    'de': 'Deutsch',
    'fr': 'Français',
    'es': 'Español',
    'it': 'Italiano',
    'pt': 'Português',
    'tr': 'Türkçe',
    'uk': 'Українська',
    'kk': 'Қазақша',
    'zh': '中文',
    'ar': 'العربية',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [
      _aboutCtl,
      _jobCtl,
      _companyCtl,
      _phoneCtl,
      _emailCtl,
      _websiteCtl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final card = await MessengerRuntime.instance.contactCards.getMy();
      List<ProfileTranslation> translations = const [];
      try {
        translations = await MessengerRuntime.instance.client.messenger
            .listMyProfileTranslations();
      } catch (_) {
        // best-effort: без переводов редактор работает как раньше
      }
      if (!mounted) return;
      setState(() {
        _loading = false;
        _exists = card != null;
        _translations = translations;
        for (final t in translations) {
          _fieldDrafts.putIfAbsent(t.locale, () => [
            t.about ?? '',
            t.jobTitle ?? '',
            t.company ?? '',
          ]);
        }
        if (card != null) {
          _template = card.template;
          _backgroundMxc = card.backgroundMxc;
          _gradientStart = card.gradientStart ?? _gradientStart;
          _gradientEnd = card.gradientEnd ?? _gradientEnd;
          _fontStyle = card.nameFontStyle ?? 'classic';
          _nameColor = card.nameColor;
          _aboutCtl.text = card.about ?? '';
          _jobCtl.text = card.jobTitle ?? '';
          _companyCtl.text = card.company ?? '';
          _phoneCtl.text = card.phone ?? '';
          _emailCtl.text = card.email ?? '';
          _websiteCtl.text = card.website ?? '';
          _contactsOnly
            ..clear()
            ..addAll(card.contactsOnlyFields);
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e;
        });
      }
    }
  }

  ContactCard _draft() => ContactCard(
    messengerUserId: 0, // сервер игнорирует — владелец всегда caller
    template: _template,
    backgroundMxc: _backgroundMxc,
    gradientStart: _gradientStart,
    gradientEnd: _gradientEnd,
    nameFontStyle: _fontStyle,
    nameColor: _nameColor,
    about: _aboutCtl.text,
    jobTitle: _jobCtl.text,
    company: _companyCtl.text,
    phone: _phoneCtl.text,
    email: _emailCtl.text,
    website: _websiteCtl.text,
    contactsOnlyFields: _contactsOnly.toList(),
    createdAt: DateTime.now().toUtc(),
    updatedAt: DateTime.now().toUtc(),
  );

  /// Превью строится из черновика + своего имени из сессии — WYSIWYG
  /// без round-trip-а.
  ContactCardInfo _previewInfo() {
    final rt = MessengerRuntime.instance;
    String? name;
    try {
      name = rt.session.displayName;
    } catch (_) {
      name = null;
    }
    return ContactCardInfo(
      ownerMessengerUserId: 0,
      displayName: name ?? '—',
      template: _template,
      backgroundMxc: _backgroundMxc,
      gradientStart: _gradientStart,
      gradientEnd: _gradientEnd,
      nameFontStyle: _fontStyle,
      nameColor: _nameColor,
      jobTitle: _jobCtl.text.trim().isEmpty ? null : _jobCtl.text.trim(),
      company: _companyCtl.text.trim().isEmpty ? null : _companyCtl.text.trim(),
      hasHiddenFields: false,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  // ─────── TASK64: версии текстовых полей по языкам ───────

  /// Переключить редактируемую версию полей: черновик текущей — в
  /// [_fieldDrafts], в контроллеры — черновик выбранной.
  void _switchFieldsLocale(String? locale) {
    if (_fieldsLocale == locale) return;
    setState(() {
      _fieldDrafts[_fieldsLocale] = [
        _aboutCtl.text,
        _jobCtl.text,
        _companyCtl.text,
      ];
      _fieldsLocale = locale;
      final d = _fieldDrafts[locale] ?? const ['', '', ''];
      _aboutCtl.text = d[0];
      _jobCtl.text = d[1];
      _companyCtl.text = d[2];
    });
  }

  Future<void> _addFieldsLocale() async {
    final l = NsgL10n.of(context);
    final existing = {..._translations.map((t) => t.locale)};
    final choices = _localeNames.entries
        .where((e) => !existing.contains(e.key))
        .toList();
    final picked = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l.profileLangAddTitle),
        children: [
          for (final e in choices)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(e.key),
              child: Text('${e.value} (${e.key.toUpperCase()})'),
            ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _fieldDrafts[picked] = const ['', '', ''];
      _translations = [
        ..._translations,
        ProfileTranslation(
          messengerUserId: 0,
          locale: picked,
          updatedAt: DateTime.now().toUtc(),
        ),
      ];
    });
    _switchFieldsLocale(picked);
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final l = NsgL10n.of(context);
    try {
      // **TASK64**: при выбранной языковой версии сохраняются ТОЛЬКО
      // переводимые поля (about/должность/компания) в перевод; стиль,
      // телефон/email/сайт и видимость — общие, правятся в основном.
      final locale = _fieldsLocale;
      if (locale != null) {
        await MessengerRuntime.instance.client.messenger
            .setProfileTranslation(
              locale: locale,
              about: _aboutCtl.text,
              jobTitle: _jobCtl.text,
              company: _companyCtl.text,
            );
        MessengerRuntime.instance.contactCards.invalidate();
        if (!mounted) return;
        setState(() {
          _saving = false;
          _fieldDrafts[locale] = [
            _aboutCtl.text,
            _jobCtl.text,
            _companyCtl.text,
          ];
        });
        messenger.showSnackBar(
          SnackBar(content: Text(l.profileLangSaved(locale.toUpperCase()))),
        );
        return;
      }
      await MessengerRuntime.instance.contactCards.setMy(_draft());
      if (!mounted) return;
      setState(() {
        _saving = false;
        _exists = true;
      });
      messenger.showSnackBar(SnackBar(content: Text(l.cardSaved)));
    } catch (e, st) {
      // Пользователь видит «не удалось сохранить» — значит и трекер обязан
      // видеть причину. Раньше ошибка глоталась (`catch (_)`), и жалобу
      // «визитка на 2 языках не сохраняется» пришлось расследовать по
      // серверным логам: под снеком скрывался
      // `MessengerNotAuthenticatedException`. Тег `card.locale` отделяет
      // сохранение языковой версии (setProfileTranslation) от основной
      // (setMyContactCard) — пути разные, ломаются по-разному.
      MessengerRuntime.instance.reportError(
        e,
        st,
        tags: {'card.locale': _fieldsLocale ?? 'base'},
      );
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(SnackBar(content: Text(l.cardSaveFailed)));
    }
  }

  Future<void> _delete() async {
    final l = NsgL10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.cardDeleteConfirmTitle),
        content: Text(l.cardDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.contactDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await MessengerRuntime.instance.contactCards.deleteMy();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e, st) {
      // Тот же снек `cardSaveFailed`, что и у сохранения, — в трекере пути
      // различает только тег.
      MessengerRuntime.instance.reportError(
        e,
        st,
        tags: {'card.action': 'delete'},
      );
      messenger.showSnackBar(SnackBar(content: Text(l.cardSaveFailed)));
    }
  }

  /// **TASK52 итер.2**: поделиться своей визиткой как vCard. Берём ПОЛНУЮ
  /// карточку с сервера (`get(myId)` — владелец видит все поля), а не
  /// preview-модель редактора (в ней нет about/phone/email/website).
  Future<void> _shareMyCard() async {
    final l = NsgL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final rt = MessengerRuntime.instance;
      final myId = rt.session.messengerUserId;
      final card = await rt.contactCards.get(myId);
      if (card == null) {
        if (!mounted) return;
        messenger.showSnackBar(SnackBar(content: Text(l.contactShareCardFailed)));
        return;
      }
      await ContactVCard.share(card, subject: card.displayName);
    } catch (e, st) {
      MessengerRuntime.instance.reportError(
        e,
        st,
        tags: {'card.action': 'share'},
      );
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l.contactShareCardFailed)));
    }
  }

  Future<void> _pickPhoto() async {
    if (_uploading) return;
    final l = NsgL10n.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final picked = await pickImageAttachment(
      ImagePicker(),
      ImageSource.gallery,
    );
    if (picked == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final ref = await MessengerRuntime.instance.client.messenger
          .uploadAttachment(
            bytes: picked.bytes.buffer.asByteData(
              picked.bytes.offsetInBytes,
              picked.bytes.lengthInBytes,
            ),
            mimeType: picked.mimeType,
            originalFilename: picked.originalFilename,
          );
      if (!mounted) return;
      setState(() {
        _uploading = false;
        _backgroundMxc = ref.mxcUrl;
        _template = 'photo';
      });
    } catch (e, st) {
      MessengerRuntime.instance.reportError(
        e,
        st,
        tags: {'card.action': 'uploadPhoto'},
      );
      if (!mounted) return;
      setState(() => _uploading = false);
      messenger.showSnackBar(SnackBar(content: Text(l.cardPhotoUploadFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          l.cardEditorTitle,
          style: const TextStyle(
            color: _fg,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _fgMuted),
        actions: [
          // **TASK52 итер.2**: поделиться своей визиткой как vCard (.vcf).
          if (_exists)
            IconButton(
              key: const Key('cardShareButton'),
              tooltip: l.contactShareMyCard,
              icon: const Icon(Icons.ios_share, color: _fgMuted),
              onPressed: _shareMyCard,
            ),
          if (_exists)
            IconButton(
              key: const Key('cardDeleteButton'),
              tooltip: l.cardDelete,
              icon: const Icon(Icons.delete_outline, color: _fgMuted),
              onPressed: _delete,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _ErrorRetry(onRetry: _load)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Live-превью.
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 260),
                    child: ContactCardView(
                      key: const Key('cardEditorPreview'),
                      card: _previewInfo(),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _sectionTitle(l.cardSectionStyle),
                const SizedBox(height: 8),
                // Шаблон.
                Wrap(
                  spacing: 8,
                  children: [
                    _chip(l.cardTemplateGradient, _template == 'gradient',
                        accent, () => setState(() => _template = 'gradient')),
                    _chip(l.cardTemplateMonogram, _template == 'monogram',
                        accent, () => setState(() => _template = 'monogram')),
                    _chip(
                      l.cardTemplatePhoto,
                      _template == 'photo',
                      accent,
                      // Фото ещё нет → сразу пикер; есть — просто шаблон.
                      () => _backgroundMxc == null
                          ? _pickPhoto()
                          : setState(() => _template = 'photo'),
                    ),
                  ],
                ),
                if (_template == 'photo') ...[
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _uploading ? null : _pickPhoto,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _fgMuted,
                        side: const BorderSide(
                          color: Color(0x1FFFFFFF),
                          width: 0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _uploading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.photo_outlined, size: 18),
                      label: Text(l.cardPickPhoto),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                // Пресеты градиента (фон gradient/monogram).
                if (_template != 'photo')
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final (start, end) in _gradientPresets)
                        GestureDetector(
                          onTap: () => setState(() {
                            _gradientStart = start;
                            _gradientEnd = end;
                          }),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  ContactCardView.parseHex(
                                      start, Colors.orange),
                                  ContactCardView.parseHex(end, Colors.black),
                                ],
                              ),
                              border: Border.all(
                                color: _gradientStart == start &&
                                        _gradientEnd == end
                                    ? accent
                                    : const Color(0x1FFFFFFF),
                                width: _gradientStart == start &&
                                        _gradientEnd == end
                                    ? 2
                                    : 0.5,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 14),
                // Начертание имени.
                Wrap(
                  spacing: 8,
                  children: [
                    _chip(l.cardFontClassic, _fontStyle == 'classic', accent,
                        () => setState(() => _fontStyle = 'classic')),
                    _chip(l.cardFontBold, _fontStyle == 'bold', accent,
                        () => setState(() => _fontStyle = 'bold')),
                    _chip(l.cardFontAiry, _fontStyle == 'airy', accent,
                        () => setState(() => _fontStyle = 'airy')),
                    _chip(l.cardFontMono, _fontStyle == 'mono', accent,
                        () => setState(() => _fontStyle = 'mono')),
                  ],
                ),
                const SizedBox(height: 14),
                // Цвет имени: авто + свотчи.
                Row(
                  children: [
                    _colorSwatch(null, accent, label: l.cardColorAuto),
                    const SizedBox(width: 10),
                    _colorSwatch('#FFFCF8', accent),
                    const SizedBox(width: 10),
                    _colorSwatch('#1A0F1A', accent),
                    const SizedBox(width: 10),
                    _colorSwatch('#E89A55', accent),
                  ],
                ),
                const SizedBox(height: 22),
                _sectionTitle(l.cardSectionFields),
                const SizedBox(height: 4),
                Text(
                  l.cardVisibilityHint,
                  style: const TextStyle(color: _fgDim, fontSize: 12),
                ),
                const SizedBox(height: 10),
                // **TASK64**: версии текстовых полей по языкам.
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(l.profileLangBase, _fieldsLocale == null, accent,
                        () => _switchFieldsLocale(null)),
                    for (final t in _translations)
                      _chip(
                        t.locale.toUpperCase(),
                        _fieldsLocale == t.locale,
                        accent,
                        () => _switchFieldsLocale(t.locale),
                      ),
                    _chip(l.profileLangAdd, false, accent, _addFieldsLocale),
                  ],
                ),
                if (_fieldsLocale != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    l.profileLangHelper(_fieldsLocale!.toUpperCase()),
                    style: const TextStyle(color: _fgDim, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 10),
                _fieldRow('about', _aboutCtl, l.cardAboutLabel, accent,
                    maxLines: 3, maxLength: 500),
                _fieldRow('jobTitle', _jobCtl, l.cardJobTitleLabel, accent),
                _fieldRow('company', _companyCtl, l.cardCompanyLabel, accent),
                // Language-neutral поля и видимость — только в основном.
                if (_fieldsLocale == null) ...[
                  _fieldRow('phone', _phoneCtl, l.cardPhoneLabel, accent),
                  _fieldRow('email', _emailCtl, l.cardEmailLabel, accent),
                  _fieldRow(
                      'website', _websiteCtl, l.cardWebsiteLabel, accent),
                ],
                const SizedBox(height: 12),
                FilledButton.icon(
                  key: const Key('cardSaveButton'),
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: _onAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(l.contactSave),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _sectionTitle(String text) => Text(
    text,
    style: const TextStyle(
      color: _label,
      fontSize: 12.5,
      fontWeight: FontWeight.w600,
    ),
  );

  Widget _chip(
    String text,
    bool selected,
    Color accent,
    VoidCallback onTap,
  ) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? accent.withValues(alpha: 0.16) : _card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected
              ? accent.withValues(alpha: 0.32)
              : const Color(0x1FFFFFFF),
          width: 0.5,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected ? _fg : _fgMuted,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );

  Widget _colorSwatch(String? hex, Color accent, {String? label}) {
    final selected = _nameColor == hex;
    final child = hex == null
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? accent.withValues(alpha: 0.16) : _card,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? accent.withValues(alpha: 0.4)
                    : const Color(0x1FFFFFFF),
                width: 0.5,
              ),
            ),
            child: Text(
              label ?? '',
              style: TextStyle(
                color: selected ? _fg : _fgMuted,
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
        : Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ContactCardView.parseHex(hex, Colors.white),
              border: Border.all(
                color: selected ? accent : const Color(0x1FFFFFFF),
                width: selected ? 2 : 0.5,
              ),
            ),
          );
    return GestureDetector(
      onTap: () => setState(() => _nameColor = hex),
      child: child,
    );
  }

  /// Поле «о себе» + переключатель видимости (suffix): глобус = все,
  /// замок = только контактам.
  Widget _fieldRow(
    String field,
    TextEditingController ctl,
    String label,
    Color accent, {
    int maxLines = 1,
    int maxLength = 128,
  }) {
    final contactsOnly = _contactsOnly.contains(field);
    final l = NsgL10n.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctl,
        maxLines: maxLines,
        maxLength: maxLength,
        style: const TextStyle(color: _fg),
        cursorColor: accent,
        onChanged: (_) => setState(() {}), // live-превью должность/компания
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: _fgDim),
          counterText: '',
          filled: true,
          fillColor: _card,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x1FFFFFFF), width: 0.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0x1FFFFFFF), width: 0.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accent),
          ),
          // Замок видимости — только в основном (видимость общая для
          // всех языковых версий поля).
          suffixIcon: _fieldsLocale != null
              ? null
              : IconButton(
            key: Key('cardVisibilityToggle-$field'),
            tooltip: contactsOnly
                ? l.cardVisibilityContacts
                : l.cardVisibilityEveryone,
            icon: Icon(
              contactsOnly ? Icons.lock_outline : Icons.public,
              size: 18,
              color: contactsOnly ? accent : _fgDim,
            ),
            onPressed: () => setState(() {
              contactsOnly
                  ? _contactsOnly.remove(field)
                  : _contactsOnly.add(field);
            }),
          ),
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            NsgL10n.of(context).contactLoadFailed,
            style: const TextStyle(color: _fgMuted),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: onRetry,
            child: Text(NsgL10n.of(context).commonRetry),
          ),
        ],
      ),
    );
  }
}
