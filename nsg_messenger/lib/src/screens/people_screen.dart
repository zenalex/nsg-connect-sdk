import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../widgets/nsg_avatar_image.dart';
import 'chat_screen.dart';
import 'contact_profile_screen.dart';
import 'contact_requests_screen.dart';

// Chatista Glass токены — сверены с дизайн-проектом CHATista
// (screen-people.jsx + prod-tokens.jsx) и боевым settings_screen.
const _bg = Color(0xFF1F1A15);
const _fg = Color(0xF5FFFCF8);
const _fgMuted = Color(0xB8FFFCF8);
const _fgDim = Color(0x80FFFCF8);
const _label = Color(0x99FFFCF8);
const _card = Color(0x14FFFFFF);
const _border = Color(0x1FFFFFFF);
const _divider = Color(0x17FFFFFF); // white 9%
const _onAccent = Color(0xFF1A0F1A);
const _sheet = Color(0xF71F1A15);

/// **TASK63 итер.2+3 — экран «Люди»** (дизайн: CHATista Glass - People).
///
/// Директория контактов: чипы-фильтр по меткам СО СЧЁТЧИКАМИ, поиск по
/// имени/@нику, счётчик «Контакты · N», строки в карточке с
/// inset-разделителями + ЦВЕТНЫЕ ТОЧКИ меток контакта,
/// kebab → action-sheet персоны (Написать / Профиль контакта).
///
/// **Итер.3**: назначения меток грузятся батчем
/// (`listLabelAssignments`) → фильтр по чипу КЛИЕНТСКИЙ (мгновенный,
/// без round-trip-а); long-press — мульти-выбор с нижней панелью
/// (назначить/снять метку сразу нескольким).
class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  List<ContactLabel> _labels = const [];
  int? _selectedLabelId;
  List<RoomParticipant>? _contacts;
  /// contactId → labelIds (из batch listLabelAssignments).
  Map<int, Set<int>> _labelsByContact = const {};
  Object? _error;
  bool _showSearch = false;
  final _searchCtl = TextEditingController();

  /// **Итер.3**: мульти-выбор (long-press входит, пустой набор = выкл).
  final Set<int> _selected = {};
  bool get _selectionMode => _selected.isNotEmpty;
  bool _batchBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _contacts = null;
    });
    final rt = MessengerRuntime.instance;
    try {
      // Итер.3: полный список + все назначения батчем — фильтр по метке
      // дальше чисто клиентский.
      final labels = await rt.contacts.listLabels();
      final contacts = await rt.rooms.listKnownContacts();
      final assignments = await rt.contacts.listLabelAssignments();
      if (!mounted) return;
      final byContact = <int, Set<int>>{};
      for (final a in assignments) {
        byContact.putIfAbsent(a.contactMessengerUserId, () => {}).add(
          a.labelId,
        );
      }
      setState(() {
        _labels = labels;
        _contacts = contacts;
        _labelsByContact = byContact;
      });
      // **TASK52 итер.2**: подтянуть счётчик входящих заявок для бейджа
      // (best-effort; ValueNotifier обновит бейдж без setState).
      unawaited(rt.contacts.refreshIncomingRequests());
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  void _selectLabel(int? labelId) {
    if (_selectedLabelId == labelId) return;
    setState(() => _selectedLabelId = labelId);
  }

  /// Счётчик контактов с меткой (для чипа). Считаем по пересечению с
  /// актуальным списком контактов — «мёртвые» назначения не завышают.
  int _labelCount(int labelId) {
    final all = _contacts ?? const <RoomParticipant>[];
    var n = 0;
    for (final c in all) {
      if (_labelsByContact[c.messengerUserId]?.contains(labelId) ?? false) {
        n++;
      }
    }
    return n;
  }

  List<RoomParticipant> get _filtered {
    var all = _contacts ?? const <RoomParticipant>[];
    final labelId = _selectedLabelId;
    if (labelId != null) {
      all = [
        for (final c in all)
          if (_labelsByContact[c.messengerUserId]?.contains(labelId) ?? false)
            c,
      ];
    }
    final q = _searchCtl.text.trim().toLowerCase();
    if (q.isEmpty) return all;
    return [
      for (final c in all)
        if ((c.displayName ?? '').toLowerCase().contains(q) ||
            (c.username ?? '').toLowerCase().contains(q))
          c,
    ];
  }

  // ─────── итер.3: мульти-выбор ───────

  void _toggleSelected(RoomParticipant c) {
    setState(() {
      _selected.contains(c.messengerUserId)
          ? _selected.remove(c.messengerUserId)
          : _selected.add(c.messengerUserId);
    });
  }

  /// Нижняя панель → «Метка»: шит меток; тап по метке назначает её всем
  /// выбранным (если она уже у ВСЕХ — снимает со всех: toggle-семантика).
  Future<void> _batchLabelSheet() async {
    final l = NsgL10n.of(context);
    if (_labels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l.peopleEmptyLabel)),
      );
      return;
    }
    final selectedIds = Set<int>.of(_selected);
    final label = await showModalBottomSheet<ContactLabel>(
      context: context,
      backgroundColor: _sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.peopleBatchLabelTitle(selectedIds.length),
                  style: const TextStyle(
                    color: _fg,
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            for (final lb in _labels)
              ListTile(
                leading: Icon(
                  _allHaveLabel(selectedIds, lb.id!)
                      ? Icons.check_circle
                      : Icons.circle_outlined,
                  color: _labelColor(lb),
                  size: 22,
                ),
                title: Text(
                  lb.name,
                  style: const TextStyle(color: _fg, fontSize: 15),
                ),
                onTap: () => Navigator.of(ctx).pop(lb),
              ),
          ],
        ),
      ),
    );
    if (label == null || !mounted) return;
    await _applyBatchLabel(selectedIds, label);
  }

  bool _allHaveLabel(Set<int> contactIds, int labelId) => contactIds.every(
    (id) => _labelsByContact[id]?.contains(labelId) ?? false,
  );

  Future<void> _applyBatchLabel(Set<int> contactIds, ContactLabel label) async {
    if (_batchBusy) return;
    setState(() => _batchBusy = true);
    final messenger = ScaffoldMessenger.of(context);
    final failText = NsgL10n.of(context).contactCreateLabelFailed;
    final assign = !_allHaveLabel(contactIds, label.id!);
    final contacts = MessengerRuntime.instance.contacts;
    try {
      for (final id in contactIds) {
        final has = _labelsByContact[id]?.contains(label.id) ?? false;
        if (has == assign) continue; // уже в целевом состоянии
        await contacts.setLabelAssigned(
          labelId: label.id!,
          contactMessengerUserId: id,
          assigned: assign,
        );
      }
      if (!mounted) return;
      setState(() {
        _selected.clear();
        _batchBusy = false;
      });
      await _load();
    } catch (e, st) {
      // Пользователь видит ошибку — трекер обязан видеть причину. Батч рвётся
      // на середине (часть контактов уже переключена), поэтому важно знать,
      // назначали метку или снимали.
      MessengerRuntime.instance.reportError(
        e,
        st,
        tags: {
          'people.action': assign ? 'batchAssignLabel' : 'batchUnassignLabel',
        },
      );
      if (!mounted) return;
      setState(() => _batchBusy = false);
      messenger.showSnackBar(SnackBar(content: Text(failText)));
      await _load(); // к серверной правде
    }
  }

  /// Цвет метки: заданный colorHex или детерминированный из имени (тот
  /// же алгоритм hue, что в NsgAvatarImage — идентичность стабильна).
  Color _labelColor(ContactLabel lb) {
    final hex = lb.colorHex;
    if (hex != null && hex.length == 7 && hex.startsWith('#')) {
      final v = int.tryParse(hex.substring(1), radix: 16);
      if (v != null) return Color(0xFF000000 | v);
    }
    var sum = 0;
    for (final c in lb.name.codeUnits) {
      sum += c;
    }
    return HSLColor.fromAHSL(1, (sum % 360).toDouble(), 0.55, 0.6).toColor();
  }

  Future<void> _openProfile(RoomParticipant c) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ContactProfileScreen(contactMessengerUserId: c.messengerUserId),
      ),
    );
    if (mounted) _load();
  }

  /// «Написать» — идемпотентный direct-чат + открыть его.
  Future<void> _openChat(RoomParticipant c) async {
    final messenger = ScaffoldMessenger.of(context);
    final failText = NsgL10n.of(context).peopleLoadFailed;
    try {
      final details = await MessengerRuntime.instance.rooms.createDirect(
        c.messengerUserId,
      );
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(roomId: details.id),
        ),
      );
    } catch (e, st) {
      MessengerRuntime.instance.reportError(
        e,
        st,
        tags: {'people.action': 'openChat'},
      );
      messenger.showSnackBar(SnackBar(content: Text(failText)));
    }
  }

  /// Action-sheet персоны (kebab / long-press): Написать / Профиль.
  Future<void> _personMenu(RoomParticipant c) async {
    final l = NsgL10n.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _sheet,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
              child: Row(
                children: [
                  NsgAvatarImage(
                    mxcUrl: c.avatarUrl,
                    fallbackName: c.displayName ?? c.matrixUserId,
                    size: 36,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.displayName ?? c.matrixUserId,
                          style: const TextStyle(
                            color: _fg,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (c.username != null)
                          Text(
                            '@${c.username}',
                            style: const TextStyle(color: _fgDim, fontSize: 12),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline, color: _fgMuted),
              title: Text(
                l.peopleWrite,
                style: const TextStyle(color: _fg, fontSize: 15.5),
              ),
              onTap: () => Navigator.of(ctx).pop('chat'),
            ),
            ListTile(
              leading: const Icon(Icons.badge_outlined, color: _fgMuted),
              title: Text(
                l.peopleProfile,
                style: const TextStyle(color: _fg, fontSize: 15.5),
              ),
              onTap: () => Navigator.of(ctx).pop('profile'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'chat') {
      await _openChat(c);
    } else {
      await _openProfile(c);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final accent = Theme.of(context).colorScheme.primary;
    final contacts = _contacts;
    final filtered = _filtered;
    return Scaffold(
      backgroundColor: _bg,
      // **Итер.3**: нижняя панель мульти-выбора.
      bottomNavigationBar: !_selectionMode
          ? null
          : SafeArea(
              child: Container(
                key: const Key('peopleSelectionBar'),
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _sheet,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border, width: 0.5),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.peopleSelectedCount(_selected.length),
                        style: const TextStyle(
                          color: _fg,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (_batchBusy)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else ...[
                      FilledButton.icon(
                        key: const Key('peopleBatchLabelButton'),
                        onPressed: _batchLabelSheet,
                        style: FilledButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: _onAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        icon: const Icon(Icons.label_outline, size: 18),
                        label: Text(
                          l.peopleAssignLabelAction,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: l.commonCancel,
                        icon: const Icon(Icons.close, color: _fgMuted),
                        onPressed: () => setState(_selected.clear),
                      ),
                    ],
                  ],
                ),
              ),
            ),
      appBar: AppBar(
        title: Text(
          l.peopleTitle,
          style: const TextStyle(
            color: _fg,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _fgMuted),
        actions: [
          // **TASK52 итер.2**: входящие карточки-заявки с бейджем-счётчиком.
          ValueListenableBuilder<int>(
            valueListenable:
                MessengerRuntime.instance.contacts.incomingRequestCount,
            builder: (ctx, count, _) => IconButton(
              key: const Key('peopleRequestsButton'),
              tooltip: NsgL10n.of(ctx).requestsTitle,
              icon: Badge(
                isLabelVisible: count > 0,
                label: Text('$count'),
                backgroundColor: accent,
                textColor: _onAccent,
                child: const Icon(Icons.mail_outline, color: _fgMuted),
              ),
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ContactRequestsScreen(),
                  ),
                );
              },
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.search,
              color: _showSearch ? accent : _fgMuted,
            ),
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              _searchCtl.clear();
            }),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border, width: 0.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, size: 18, color: _fgMuted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchCtl,
                        autofocus: true,
                        cursorColor: accent,
                        style: const TextStyle(color: _fg, fontSize: 15),
                        decoration: InputDecoration(
                          hintText: l.peopleSearchHint,
                          hintStyle:
                              const TextStyle(color: _fgDim, fontSize: 15),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    if (_searchCtl.text.isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(_searchCtl.clear),
                        child: const Icon(Icons.close, size: 18, color: _fgDim),
                      ),
                  ],
                ),
              ),
            ),
          // Чипы-фильтр: «Все» + метки.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                _filterChip(
                  label: l.peopleAll,
                  count: contacts?.length,
                  selected: _selectedLabelId == null,
                  accent: accent,
                  onTap: () => _selectLabel(null),
                ),
                for (final lb in _labels) ...[
                  const SizedBox(width: 8),
                  _filterChip(
                    label: lb.name,
                    count: contacts == null ? null : _labelCount(lb.id!),
                    dotColor: _labelColor(lb),
                    selected: _selectedLabelId == lb.id,
                    accent: accent,
                    onTap: () => _selectLabel(lb.id),
                  ),
                ],
              ],
            ),
          ),
          // Секция-лейбл «Контакты · N».
          if (contacts != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                filtered.isEmpty
                    ? l.peopleNotFound
                    : l.peopleCount(filtered.length),
                style: const TextStyle(
                  color: _label,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          Expanded(
            child: _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l.peopleLoadFailed,
                          style: const TextStyle(color: _fgMuted),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: _load,
                          child: Text(l.commonRetry),
                        ),
                      ],
                    ),
                  )
                : contacts == null
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        _selectedLabelId == null
                            ? l.peopleEmpty
                            : l.peopleEmptyLabel,
                        style: const TextStyle(color: _fgDim, fontSize: 13.5),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                      children: [
                        // Карточка-контейнер списка (PCard из макета).
                        Container(
                          decoration: BoxDecoration(
                            color: _card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _border, width: 0.5),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              for (var i = 0; i < filtered.length; i++)
                                _personRow(
                                  filtered[i],
                                  last: i == filtered.length - 1,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  /// Строка персоны по макету: avatar 44 → имя 15.5 w500 + @ник 12.5 dim
  /// + точки меток → kebab; inset-разделитель от текста (не от края).
  /// **Итер.3**: long-press — мульти-выбор; в selection-mode tap
  /// переключает выбор, выбранные — галка на месте аватара.
  Widget _personRow(RoomParticipant c, {required bool last}) {
    final selected = _selected.contains(c.messengerUserId);
    final labelIds = _labelsByContact[c.messengerUserId] ?? const <int>{};
    final dots = [
      for (final lb in _labels)
        if (labelIds.contains(lb.id)) _labelColor(lb),
    ];
    final accent = Theme.of(context).colorScheme.primary;
    return InkWell(
      onTap: _selectionMode
          ? () => _toggleSelected(c)
          : () => _openProfile(c),
      onLongPress: () => _toggleSelected(c),
      highlightColor: Colors.white.withValues(alpha: 0.04),
      splashColor: Colors.white.withValues(alpha: 0.06),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              children: [
                if (selected)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accent.withValues(alpha: 0.2),
                      border: Border.all(color: accent, width: 1.5),
                    ),
                    child: Icon(Icons.check, color: accent, size: 22),
                  )
                else
                  NsgAvatarImage(
                    mxcUrl: c.avatarUrl,
                    fallbackName: c.displayName ?? c.matrixUserId,
                    size: 44,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.displayName ?? c.matrixUserId,
                        style: const TextStyle(
                          color: _fg,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          // Итер.3: точки-метки перед @ником (≤4).
                          for (final color in dots.take(4)) ...[
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          if (dots.isNotEmpty) const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              c.username != null
                                  ? '@${c.username}'
                                  : c.matrixUserId,
                              style: const TextStyle(
                                color: _fgDim,
                                fontSize: 12.5,
                                letterSpacing: -0.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!_selectionMode)
                  IconButton(
                    icon: const Icon(Icons.more_vert, size: 20, color: _fgDim),
                    onPressed: () => _personMenu(c),
                  ),
              ],
            ),
          ),
          if (!last)
            const Positioned(
              left: 14 + 44 + 12,
              right: 0,
              bottom: 0,
              child: SizedBox(
                height: 0.5,
                child: ColoredBox(color: _divider),
              ),
            ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required Color accent,
    required VoidCallback onTap,
    int? count,
    Color? dotColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? accent : _card,
          borderRadius: BorderRadius.circular(999),
          border: selected ? null : Border.all(color: _border, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dotColor != null) ...[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? _onAccent : dotColor,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              // Итер.3: счётчик на чипе («Работа · 3»).
              count == null ? label : '$label · $count',
              style: TextStyle(
                color: selected ? _onAccent : _fgMuted,
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
