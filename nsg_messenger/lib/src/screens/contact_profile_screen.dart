import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../contact_card/contact_card_view.dart';
import '../contact_card/vcard.dart';
import '../contacts/nsg_messenger_contacts.dart';
import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../theme/overlay_surface.dart';
import '../widgets/nsg_avatar_image.dart';
import 'chat_screen.dart';

// Chatista Glass токены (docs/design/chatista-glass-design-prompt.md).
const _bg = Color(0xFF1F1A15);
const _fg = Color(0xF5FFFCF8);
const _fgMuted = Color(0xB8FFFCF8);
const _fgDim = Color(0x80FFFCF8);
const _label = Color(0x99FFFCF8);
const _card = Color(0x14FFFFFF);
const _onAccent = Color(0xFF1A0F1A);

InputDecoration _glassInput({
  required String labelText,
  required String helperText,
  required Color accent,
}) => InputDecoration(
  labelText: labelText,
  helperText: helperText,
  labelStyle: const TextStyle(color: _fgDim),
  helperStyle: const TextStyle(color: _fgDim, fontSize: 11.5),
  counterStyle: const TextStyle(color: _fgDim, fontSize: 11),
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
);

/// **TASK63**: профиль контакта глазами текущего пользователя.
///
/// Показывает публичные поля (реальное имя / @username / аватар) и даёт
/// редактировать ПРИВАТНЫЕ per-viewer данные:
///   * «Своё имя» (alias) — подменяет имя контакта в списке чатов и
///     участниках (применяет сервер);
///   * заметку;
///   * метки (чипы-toggle; создание новой — с подсказками по умолчанию
///     при пустом списке).
///
/// RU-строки хардкодом (как MyTicketsScreen) — l10n итерацией 2.
class ContactProfileScreen extends StatefulWidget {
  const ContactProfileScreen({super.key, required this.contactMessengerUserId});

  final int contactMessengerUserId;

  @override
  State<ContactProfileScreen> createState() => _ContactProfileScreenState();
}

class _ContactProfileScreenState extends State<ContactProfileScreen> {
  NsgMessengerContacts get _contacts => MessengerRuntime.instance.contacts;

  ContactProfileView? _profile;
  List<ContactLabel> _labels = const [];
  // **TASK52**: визитка контакта (best-effort; null = нет/не загрузилась).
  ContactCardInfo? _cardInfo;
  // **TASK52 итер.2**: отношение (контакт? заблокирован мной?) — best-effort.
  ContactRelation? _relation;
  Object? _error;
  bool _saving = false;
  // Флаг «идёт блок/разблок» — блокирует повторные тапы по меню.
  bool _relationBusy = false;

  final _nameCtl = TextEditingController();
  final _noteCtl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _noteCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final profile = await _contacts.getProfile(widget.contactMessengerUserId);
      final labels = await _contacts.listLabels();
      // Визитка — best-effort: её отсутствие/ошибка не валит профиль.
      ContactCardInfo? card;
      try {
        card = await MessengerRuntime.instance.contactCards.get(
          widget.contactMessengerUserId,
        );
      } catch (_) {}
      // Отношение — best-effort: для меню блок/разблок.
      ContactRelation? relation;
      try {
        relation = await _contacts.relation(widget.contactMessengerUserId);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _labels = labels;
        _cardInfo = card;
        _relation = relation;
        _nameCtl.text = profile.customName ?? '';
        _noteCtl.text = profile.note ?? '';
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  /// Сохранить alias+заметку. Пустые поля = очистка. После смены alias
  /// сбрасываем кэш комнат — имя в списке чатов обновится при refresh.
  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final updated = await _contacts.setMeta(
        contactMessengerUserId: widget.contactMessengerUserId,
        customName: _nameCtl.text,
        note: _noteCtl.text,
      );
      MessengerRuntime.instance.rooms.invalidate();
      if (!mounted) return;
      setState(() => _profile = updated);
      messenger.showSnackBar(
        SnackBar(content: Text(NsgL10n.of(context).contactSaved)),
      );
    } catch (e, st) {
      _reportActionFailed(e, st, 'saveMeta');
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(NsgL10n.of(context).contactSaveFailed)),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleLabel(ContactLabel label, bool assigned) async {
    final profile = _profile;
    if (profile == null) return;
    // Оптимистично.
    setState(() {
      final ids = List<int>.of(profile.labelIds);
      assigned ? ids.add(label.id!) : ids.remove(label.id);
      _profile = ContactProfileView(
        contactMessengerUserId: profile.contactMessengerUserId,
        displayName: profile.displayName,
        username: profile.username,
        avatarUrl: profile.avatarUrl,
        customName: profile.customName,
        note: profile.note,
        labelIds: ids,
      );
    });
    try {
      await _contacts.setLabelAssigned(
        labelId: label.id!,
        contactMessengerUserId: widget.contactMessengerUserId,
        assigned: assigned,
      );
    } catch (_) {
      if (mounted) _load(); // revert к серверной правде
    }
  }

  Future<void> _createLabel() async {
    final suggestions = _labels.isEmpty
        ? NsgMessengerContacts.defaultLabelSuggestions
        : const <String>[];
    final ctl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(NsgL10n.of(context).contactNewLabel),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: ctl,
              autofocus: true,
              maxLength: 32,
              decoration: InputDecoration(
                hintText: NsgL10n.of(context).contactNewLabelHint,
              ),
              onSubmitted: (v) => Navigator.of(ctx).pop(v),
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: [
                  for (final s in suggestions)
                    ActionChip(
                      label: Text(s),
                      onPressed: () => Navigator.of(ctx).pop(s),
                    ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(NsgL10n.of(context).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(ctl.text),
            child: Text(NsgL10n.of(context).contactCreate),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final l = NsgL10n.of(context);
    try {
      final created = await _contacts.createLabel(name.trim());
      // Сразу вешаем новую метку на текущий контакт.
      await _contacts.setLabelAssigned(
        labelId: created.id!,
        contactMessengerUserId: widget.contactMessengerUserId,
        assigned: true,
      );
      await _load();
    } catch (e, st) {
      // Метка либо не создалась, либо не навесилась на контакт — снек один,
      // и по нему не различить; в трекере хотя бы виден стек.
      _reportActionFailed(e, st, 'createLabel');
      messenger.showSnackBar(
        SnackBar(content: Text(l.contactCreateLabelFailed)),
      );
    }
  }

  /// Отправить в трекер ошибку действия над контактом, которую увидел
  /// пользователь. Тег [action] отделяет пути друг от друга: снеки разные,
  /// но в трекере важно, какое именно действие сломалось.
  ///
  /// Ожидаемые отказы репортить НЕ надо — они ловятся отдельными `on`-ветками
  /// выше (гейт приватности `PeerUnavailableException`, кулдаун
  /// `RateLimitExceededException`): это не баги, а штатный ответ сервера.
  void _reportActionFailed(Object e, StackTrace st, String action) {
    MessengerRuntime.instance.reportError(
      e,
      st,
      tags: {'contact.action': action},
    );
  }

  /// «Написать» (макет screen-contact): идемпотентный direct + переход.
  ///
  /// **TASK52 итер.2**: если peer закрыл «кто может мне писать» (или
  /// заблокировал) — сервер бросает [PeerUnavailableException] (без полей,
  /// anti-enumeration). Но здесь мы уже видим этого человека легитимно
  /// (открыли его профиль), значит отказ = гейт приватности. Предлагаем
  /// отправить заявку со своей визиткой (send молчалив при блоке — ничего
  /// не «протекает»).
  Future<void> _openChat() async {
    final messenger = ScaffoldMessenger.of(context);
    final failText = NsgL10n.of(context).peopleLoadFailed;
    try {
      final details = await MessengerRuntime.instance.rooms.createDirect(
        widget.contactMessengerUserId,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => ChatScreen(roomId: details.id)),
      );
    } on PeerUnavailableException {
      if (mounted) await _offerContactRequest();
    } catch (e, st) {
      _reportActionFailed(e, st, 'openChat');
      messenger.showSnackBar(SnackBar(content: Text(failText)));
    }
  }

  /// Диалог «написать напрямую нельзя → отправить заявку».
  Future<void> _offerContactRequest() async {
    final l = NsgL10n.of(context);
    final name = _profile?.displayName ?? '';
    final send = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _bg,
        title: Text(
          l.contactRequestOfferTitle,
          style: const TextStyle(color: _fg, fontSize: 17),
        ),
        content: Text(
          l.contactRequestOfferBody(name),
          style: const TextStyle(color: _fgMuted, fontSize: 14, height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(NsgL10n.of(ctx).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.contactRequestSend),
          ),
        ],
      ),
    );
    if (send == true) await _sendContactRequest();
  }

  Future<void> _sendContactRequest() async {
    final messenger = ScaffoldMessenger.of(context);
    final l = NsgL10n.of(context);
    try {
      await _contacts.sendContactRequest(widget.contactMessengerUserId);
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l.contactRequestSent)));
    } on RateLimitExceededException {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l.contactRequestCooldown)),
      );
    } catch (e, st) {
      _reportActionFailed(e, st, 'sendContactRequest');
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l.contactRequestSendFailed)),
      );
    }
  }

  /// **TASK52 итер.2**: экспорт визитки контакта в системную адресную
  /// книгу (vCard .vcf через share sheet).
  Future<void> _saveToContacts() async {
    final card = _cardInfo;
    if (card == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final l = NsgL10n.of(context);
    // Подставляем регистрационный email, если в визитке его нет — чтобы
    // сохранённый контакт не остался без email (он есть всегда).
    final accEmail = _profile?.email;
    final needsEmail = card.email == null || card.email!.trim().isEmpty;
    final toShare = (needsEmail && accEmail != null && accEmail.isNotEmpty)
        ? card.copyWith(email: accEmail)
        : card;
    try {
      await ContactVCard.share(toShare);
    } catch (e, st) {
      _reportActionFailed(e, st, 'saveToContacts');
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l.contactSaveFailed)));
    }
  }

  /// **TASK52 итер.2**: заблокировать (с подтверждением) / разблокировать.
  Future<void> _toggleBlock() async {
    if (_relationBusy) return;
    final messenger = ScaffoldMessenger.of(context);
    final l = NsgL10n.of(context);
    final blocked = _relation?.blockedByMe ?? false;
    final id = widget.contactMessengerUserId;

    if (!blocked) {
      final name = _profile?.displayName ?? '';
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: _bg,
          title: Text(
            l.contactBlockConfirm(name),
            style: const TextStyle(color: _fg, fontSize: 17),
          ),
          content: Text(
            l.contactBlockBody,
            style: const TextStyle(color: _fgMuted, fontSize: 14, height: 1.35),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(NsgL10n.of(ctx).commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
              child: Text(l.contactBlock),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }

    setState(() => _relationBusy = true);
    try {
      if (blocked) {
        await _contacts.unblockUser(id);
      } else {
        await _contacts.blockUser(id);
      }
      final fresh = await _contacts.relation(id);
      if (!mounted) return;
      setState(() {
        _relation = fresh;
        _relationBusy = false;
      });
      messenger.showSnackBar(
        SnackBar(
          content: Text(blocked ? l.contactUnblocked : l.contactBlocked),
        ),
      );
    } catch (e, st) {
      _reportActionFailed(e, st, blocked ? 'unblock' : 'block');
      if (!mounted) return;
      setState(() => _relationBusy = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(blocked ? l.contactUnblockFailed : l.contactBlockFailed),
        ),
      );
    }
  }

  /// Долг TASK63: управление меткой — переименовать / удалить (long-press
  /// по чипу). Удаление снимает метку со ВСЕХ контактов (подтверждение).
  Future<void> _labelMenu(ContactLabel label) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: kOverlaySurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: _fgMuted),
              title: Text(
                NsgL10n.of(context).contactRenameLabelMenu(label.name),
                style: const TextStyle(color: _fg, fontSize: 15),
              ),
              onTap: () => Navigator.of(ctx).pop('rename'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: _fgMuted),
              title: Text(
                NsgL10n.of(context).contactDeleteLabel,
                style: const TextStyle(color: _fg, fontSize: 15),
              ),
              onTap: () => Navigator.of(ctx).pop('delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final l = NsgL10n.of(context);

    if (action == 'rename') {
      final ctl = TextEditingController(text: label.name);
      final name = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(NsgL10n.of(context).contactRenameLabelTitle),
          content: TextField(
            controller: ctl,
            autofocus: true,
            maxLength: 32,
            onSubmitted: (v) => Navigator.of(ctx).pop(v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(NsgL10n.of(context).commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(ctl.text),
              child: Text(NsgL10n.of(context).contactSave),
            ),
          ],
        ),
      );
      if (name == null || name.trim().isEmpty || !mounted) return;
      try {
        await _contacts.renameLabel(label.id!, name.trim());
        await _load();
      } catch (e, st) {
        _reportActionFailed(e, st, 'renameLabel');
        messenger.showSnackBar(
          SnackBar(content: Text(l.contactRenameFailed)),
        );
      }
      return;
    }

    // delete — подтверждение (снимется со всех контактов).
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(NsgL10n.of(context).contactDeleteLabelConfirm(label.name)),
        content: Text(NsgL10n.of(context).contactDeleteLabelBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(NsgL10n.of(context).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(NsgL10n.of(context).contactDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await _contacts.deleteLabel(label.id!);
      await _load();
    } catch (e, st) {
      _reportActionFailed(e, st, 'deleteLabel');
      messenger.showSnackBar(
        SnackBar(content: Text(l.contactDeleteLabelFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final accent = Theme.of(context).colorScheme.primary;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Text(
          NsgL10n.of(context).contactTitle,
          style: TextStyle(color: _fg, fontSize: 17, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _fgMuted),
        actions: [
          // **TASK52 итер.2**: меню действий — блок/разблок + «сохранить в
          // контакты» (vCard). Появляется, когда есть отношение или визитка.
          if (_relation != null || _cardInfo != null)
            PopupMenuButton<String>(
              key: const Key('contactRelationMenu'),
              icon: _relationBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _fgMuted,
                      ),
                    )
                  : const Icon(Icons.more_vert, color: _fgMuted),
              color: const Color(0xFF2A241D),
              onSelected: (v) {
                if (v == 'block' || v == 'unblock') _toggleBlock();
                if (v == 'saveVcard') _saveToContacts();
              },
              itemBuilder: (ctx) {
                final l = NsgL10n.of(ctx);
                return [
                  if (_cardInfo != null)
                    PopupMenuItem<String>(
                      value: 'saveVcard',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person_add_alt,
                            size: 20,
                            color: _fgMuted,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            l.contactSaveToContacts,
                            style: const TextStyle(color: _fg, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  if (_relation != null)
                    PopupMenuItem<String>(
                      value: _relation!.blockedByMe ? 'unblock' : 'block',
                      child: Row(
                        children: [
                          Icon(
                            _relation!.blockedByMe
                                ? Icons.lock_open
                                : Icons.block,
                            size: 20,
                            color: _relation!.blockedByMe
                                ? _fgMuted
                                : Colors.red.shade400,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _relation!.blockedByMe
                                ? l.contactUnblock
                                : l.contactBlock,
                            style: TextStyle(
                              color: _relation!.blockedByMe
                                  ? _fg
                                  : Colors.red.shade400,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                ];
              },
            ),
        ],
      ),
      body: _error != null
          ? _ErrorRetry(onRetry: _load)
          : profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header по макету screen-contact: аватар 96 по центру,
                // имя 22 w600, @ник АКЦЕНТОМ 14 w600.
                Column(
                  children: [
                    const SizedBox(height: 4),
                    NsgAvatarImage(
                      mxcUrl: profile.avatarUrl,
                      fallbackName: profile.displayName ?? '?',
                      size: 96,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      profile.displayName ?? '—',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _fg,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.4,
                      ),
                    ),
                    if (profile.username != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        '@${profile.username}',
                        style: TextStyle(
                          color: accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    // Кнопка-действие (макет: «Сообщение» filled).
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _openChat,
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: _onAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.chat_bubble_outline, size: 20),
                        label: Text(
                          NsgL10n.of(context).peopleWrite,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    // **TASK52 итер.2**: чип «заблокирован» — состояние видно
                    // сразу, разблок через меню в шапке.
                    if (_relation?.blockedByMe == true) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0x1FFF5252),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.block, size: 15, color: Colors.red.shade300),
                            const SizedBox(width: 7),
                            Text(
                              NsgL10n.of(context).contactBlocked,
                              style: TextStyle(
                                color: Colors.red.shade300,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                // **TASK52**: визитка контакта (визуал) — только если есть.
                if (_cardInfo != null) ...[
                  const SizedBox(height: 20),
                  ContactCardView(
                    key: const Key('contactProfileCard'),
                    card: _cardInfo!,
                    size: ContactCardSize.tile,
                  ),
                ],
                // **TASK52 итер.2**: контактные поля — из визитки + fallback
                // на регистрационный email профиля (есть всегда). Рендерится
                // даже без визитки.
                if (_cardInfo != null || profile.email != null) ...[
                  const SizedBox(height: 12),
                  _CardFields(card: _cardInfo, accountEmail: profile.email),
                ],
                const SizedBox(height: 20),
                TextField(
                  controller: _nameCtl,
                  maxLength: 64,
                  style: const TextStyle(color: _fg),
                  cursorColor: accent,
                  decoration: _glassInput(
                    labelText: NsgL10n.of(context).contactCustomNameLabel,
                    helperText: NsgL10n.of(context).contactCustomNameHelper,
                    accent: accent,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteCtl,
                  maxLength: 2000,
                  maxLines: 4,
                  minLines: 2,
                  style: const TextStyle(color: _fg),
                  cursorColor: accent,
                  decoration: _glassInput(
                    labelText: NsgL10n.of(context).contactNoteLabel,
                    helperText: NsgL10n.of(context).contactNoteHelper,
                    accent: accent,
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: _onAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(NsgL10n.of(context).contactSave),
                ),
                const SizedBox(height: 24),
                Text(
                  NsgL10n.of(context).contactLabelsTitle,
                  style: TextStyle(
                    color: _label,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Чипы по макету screen-contact: назначенная —
                    // акцент 16% bg + 32% border + fg; прочие — card-тон.
                    for (final label in _labels)
                      GestureDetector(
                        onLongPress: () => _labelMenu(label),
                        onTap: () => _toggleLabel(
                          label,
                          !profile.labelIds.contains(label.id),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: profile.labelIds.contains(label.id)
                                ? accent.withValues(alpha: 0.16)
                                : _card,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: profile.labelIds.contains(label.id)
                                  ? accent.withValues(alpha: 0.32)
                                  : const Color(0x1FFFFFFF),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            label.name,
                            style: TextStyle(
                              color: profile.labelIds.contains(label.id)
                                  ? _fg
                                  : _fgMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    // «+ Метка» — dashed-стиль пилюли (макет).
                    GestureDetector(
                      onTap: _createLabel,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0x4DFFFCF8),
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add, size: 15, color: _fgMuted),
                            const SizedBox(width: 5),
                            Text(
                              NsgL10n.of(context).contactNewLabel,
                              style: const TextStyle(
                                color: _fgMuted,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

/// **TASK52**: поля визитки (то, что сервер отдал ЭТОМУ смотрящему —
/// contacts-only уже вырезаны) + подсказка про скрытые поля.
class _CardFields extends StatelessWidget {
  const _CardFields({required this.card, this.accountEmail});

  /// Визитка (может отсутствовать — тогда показываем только accountEmail).
  final ContactCardInfo? card;

  /// **TASK52 итер.2**: регистрационный email профиля — fallback, если в
  /// визитке email не задан (или визитки нет вовсе).
  final String? accountEmail;

  /// Скопировать значение поля в буфер + snackbar «Скопировано».
  void _copy(BuildContext context, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(NsgL10n.of(context).messageCopiedSnack),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final c = card;
    final about = c?.about?.trim();
    final cardEmail = c?.email?.trim();
    // email визитки в приоритете; иначе — регистрационный email профиля.
    final email = (cardEmail != null && cardEmail.isNotEmpty)
        ? cardEmail
        : accountEmail?.trim();
    // Контактные поля — тап копирует (телефон/email/сайт).
    final contacts = <(IconData, String)>[
      if (c?.phone != null && c!.phone!.trim().isNotEmpty)
        (Icons.phone_outlined, c.phone!.trim()),
      if (email != null && email.isNotEmpty) (Icons.mail_outline, email),
      if (c?.website != null && c!.website!.trim().isNotEmpty)
        (Icons.language_outlined, c.website!.trim()),
    ];
    final hasAbout = about != null && about.isNotEmpty;
    final hasHidden = c?.hasHiddenFields ?? false;
    if (!hasAbout && contacts.isEmpty && !hasHidden) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1FFFFFFF), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // «О себе» — длинный текст, оставляем выделяемым (не copy-on-tap).
          if (hasAbout)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notes_outlined, size: 18, color: _fgDim),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SelectableText(
                      about,
                      style: const TextStyle(color: _fg, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          // Контакты — тап по строке копирует значение.
          for (final (icon, text) in contacts)
            InkWell(
              onTap: () => _copy(context, text),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Icon(icon, size: 18, color: _fgDim),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(color: _fg, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.copy_rounded, size: 15, color: _fgDim),
                  ],
                ),
              ),
            ),
          if (hasHidden)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline, size: 16, color: _fgDim),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.cardHiddenFieldsNote,
                      style: const TextStyle(color: _fgDim, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
        ],
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
            style: TextStyle(color: _fgMuted),
          ),
          const SizedBox(height: 8),
          FilledButton(onPressed: onRetry, child: Text(NsgL10n.of(context).commonRetry)),
        ],
      ),
    );
  }
}
