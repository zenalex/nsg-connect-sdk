import 'package:flutter/foundation.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../messenger_runtime.dart';
import '../session/auth_retry.dart';
import '../session/messenger_session_manager.dart';

/// **TASK63**: организация контактов — per-viewer «своё имя» (alias),
/// заметка и метки. Тонкий RPC-фасад (`NsgMessenger.contacts`) поверх
/// `client.messenger.*` с [withAuthRetry]; лёгкий кэш списка меток.
///
/// Всё приватно per-viewer: alias/заметки/метки видит только владелец.
/// Alias применяется СЕРВЕРОМ в выдаче (имя direct-чата, участники) —
/// клиенту дополнительно ничего мапить не нужно; после изменения alias
/// достаточно invalidate списка комнат (`NsgMessenger.rooms.invalidate()`).
class NsgMessengerContacts {
  NsgMessengerContacts.attach(Client client) : _client = client;

  final Client _client;

  MessengerSessionManager get _session =>
      MessengerRuntime.instance.sessionManager;

  /// Кэш `listContactLabels` (single-entry, TTL 30с — как rooms.list).
  List<ContactLabel>? _labelsCache;
  DateTime? _labelsFetchedAt;
  static const Duration _labelsTtl = Duration(seconds: 30);

  /// **Итер.3**: кэш `listContactLabelAssignments` (тот же TTL).
  List<ContactLabelAssignment>? _assignmentsCache;
  DateTime? _assignmentsFetchedAt;

  /// Подсказки для пустого списка меток (UI-чипы при первом использовании;
  /// в БД НЕ сидируются — см. TASK63 §2).
  static const List<String> defaultLabelSuggestions = [
    'Личные',
    'Работа',
    'Семья',
  ];

  /// Профиль контакта глазами текущего пользователя.
  Future<ContactProfileView> getProfile(int contactMessengerUserId) =>
      withAuthRetry(
        () => _client.messenger.getContactProfile(
          contactMessengerUserId: contactMessengerUserId,
        ),
        _session,
      );

  /// Задать «своё имя»/заметку. null = не менять, пустая строка = очистить.
  /// После смены alias вызывающий UI должен `rooms.invalidate()` +
  /// refresh, чтобы имя в списке чатов обновилось.
  Future<ContactProfileView> setMeta({
    required int contactMessengerUserId,
    String? customName,
    String? note,
  }) => withAuthRetry(
    () => _client.messenger.setContactMeta(
      contactMessengerUserId: contactMessengerUserId,
      customName: customName,
      note: note,
    ),
    _session,
  );

  /// Метки текущего пользователя (кэш TTL 30с).
  Future<List<ContactLabel>> listLabels({bool force = false}) async {
    final cached = _labelsCache;
    final at = _labelsFetchedAt;
    if (!force &&
        cached != null &&
        at != null &&
        DateTime.now().difference(at) < _labelsTtl) {
      return cached;
    }
    final fresh = await withAuthRetry(
      () => _client.messenger.listContactLabels(),
      _session,
    );
    _labelsCache = fresh;
    _labelsFetchedAt = DateTime.now();
    return fresh;
  }

  void invalidateLabels() {
    _labelsCache = null;
    _labelsFetchedAt = null;
    _assignmentsCache = null;
    _assignmentsFetchedAt = null;
  }

  Future<ContactLabel> createLabel(String name, {String? colorHex}) async {
    final created = await withAuthRetry(
      () => _client.messenger.createContactLabel(
        name: name,
        colorHex: colorHex,
      ),
      _session,
    );
    invalidateLabels();
    return created;
  }

  Future<ContactLabel> renameLabel(
    int labelId,
    String name, {
    String? colorHex,
  }) async {
    final renamed = await withAuthRetry(
      () => _client.messenger.renameContactLabel(
        labelId: labelId,
        name: name,
        colorHex: colorHex,
      ),
      _session,
    );
    invalidateLabels();
    return renamed;
  }

  Future<void> deleteLabel(int labelId) async {
    await withAuthRetry(
      () => _client.messenger.deleteContactLabel(labelId: labelId),
      _session,
    );
    invalidateLabels();
  }

  /// Повесить/снять метку с контакта (идемпотентно).
  Future<void> setLabelAssigned({
    required int labelId,
    required int contactMessengerUserId,
    required bool assigned,
  }) => withAuthRetry(
    () => _client.messenger.setContactLabelAssigned(
      labelId: labelId,
      contactMessengerUserId: contactMessengerUserId,
      assigned: assigned,
    ),
    _session,
  );

  /// Директория: контакты с меткой (имена уже с alias-ами).
  Future<List<RoomParticipant>> listContactsByLabel(int labelId) =>
      withAuthRetry(
        () => _client.messenger.listContactsByLabel(labelId: labelId),
        _session,
      );

  /// **Итер.3 («Люди»)**: все назначения меток одним запросом — для
  /// точек-меток на строках, счётчиков на чипах и клиентского фильтра.
  /// Кэш с тем же TTL, что и метки; сбрасывается [invalidateLabels].
  Future<List<ContactLabelAssignment>> listLabelAssignments() async {
    final cached = _assignmentsCache;
    final at = _assignmentsFetchedAt;
    if (cached != null &&
        at != null &&
        DateTime.now().difference(at) < _labelsTtl) {
      return cached;
    }
    final fresh = await withAuthRetry(
      () => _client.messenger.listContactLabelAssignments(),
      _session,
    );
    _assignmentsCache = fresh;
    _assignmentsFetchedAt = DateTime.now();
    return fresh;
  }

  // ─── TASK52 итер.2: trust-связи + блокировка ───────────────────────

  /// Отношение к пользователю (контакт? заблокирован мной?) — для UI
  /// профиля/интро-карточки.
  Future<ContactRelation> relation(int otherMessengerUserId) => withAuthRetry(
    () => _client.messenger.getContactRelation(
      otherMessengerUserId: otherMessengerUserId,
    ),
    _session,
  );

  /// Добавить/убрать в контакты (даёт пройти мой гейт «кто может писать»).
  Future<void> addContact(int contactMessengerUserId) => withAuthRetry(
    () => _client.messenger.addContact(
      contactMessengerUserId: contactMessengerUserId,
    ),
    _session,
  );

  Future<void> removeContact(int contactMessengerUserId) => withAuthRetry(
    () => _client.messenger.removeContact(
      contactMessengerUserId: contactMessengerUserId,
    ),
    _session,
  );

  Future<void> blockUser(int targetMessengerUserId) => withAuthRetry(
    () => _client.messenger.blockUser(
      targetMessengerUserId: targetMessengerUserId,
    ),
    _session,
  );

  Future<void> unblockUser(int targetMessengerUserId) => withAuthRetry(
    () => _client.messenger.unblockUser(
      targetMessengerUserId: targetMessengerUserId,
    ),
    _session,
  );

  // ─── TASK52 итер.2: карточки-заявки (message-request) ──────────────

  /// **Реактивный счётчик входящих заявок** — для бейджа. Обновляется
  /// при [refreshIncomingRequests] (зовётся runtime-ом на событии
  /// `contactRequestChanged`) и после accept/decline.
  final ValueNotifier<int> incomingRequestCount = ValueNotifier<int>(0);

  List<ContactRequestView>? _incomingCache;
  DateTime? _incomingFetchedAt;

  /// Отправить заявку «показать визитку». Молчаливо «успешна» при
  /// блокировке (anti-enumeration); cooldown/лимит → бросает
  /// RateLimitExceededException.
  Future<void> sendContactRequest(
    int toMessengerUserId, {
    String? note,
  }) => withAuthRetry(
    () => _client.messenger.sendContactRequest(
      toMessengerUserId: toMessengerUserId,
      note: note,
    ),
    _session,
  );

  /// Мои входящие заявки (pending) с кэшем (TTL 30с). Обновляет
  /// [incomingRequestCount].
  Future<List<ContactRequestView>> listIncomingRequests({
    bool force = false,
  }) async {
    final cached = _incomingCache;
    final at = _incomingFetchedAt;
    if (!force &&
        cached != null &&
        at != null &&
        DateTime.now().difference(at) < _labelsTtl) {
      return cached;
    }
    final fresh = await withAuthRetry(
      () => _client.messenger.listIncomingContactRequests(),
      _session,
    );
    _incomingCache = fresh;
    _incomingFetchedAt = DateTime.now();
    incomingRequestCount.value = fresh.length;
    return fresh;
  }

  /// Realtime-сброс + фоновый пересчёт бейджа (зовётся из runtime на
  /// событии `contactRequestChanged`).
  Future<void> refreshIncomingRequests() async {
    _incomingCache = null;
    _incomingFetchedAt = null;
    try {
      await listIncomingRequests(force: true);
    } catch (_) {
      // best-effort — бейдж обновится при следующем открытии экрана
    }
  }

  /// Принять заявку → взаимный контакт + direct-чат (RoomDetails).
  Future<RoomDetails> acceptContactRequest(int requestId) async {
    final room = await withAuthRetry(
      () => _client.messenger.acceptContactRequest(requestId: requestId),
      _session,
    );
    await refreshIncomingRequests();
    MessengerRuntime.instance.rooms.invalidate();
    return room;
  }

  /// Отклонить заявку.
  Future<void> declineContactRequest(int requestId) async {
    await withAuthRetry(
      () => _client.messenger.declineContactRequest(requestId: requestId),
      _session,
    );
    await refreshIncomingRequests();
  }

  // ─── TASK52 итер.2 (чанк 3): обмен визитками через trust-токен ──────

  /// Выдать эфемерный trust-токен (QR / «Рядом» / инвайт-ссылка). Единый
  /// механизм — потребитель различается [kind].
  Future<TrustTokenIssued> issueTrustToken(TrustTokenKind kind) =>
      withAuthRetry(
        () => _client.messenger.issueTrustToken(kind: kind),
        _session,
      );

  /// Погасить trust-токен → взаимный контакт. Возврат — с кем связались
  /// (для direct-чата/интро), либо null на любой невалидный исход (нет
  /// токена / истёк / исчерпан / свой / чужой tenant — тихо).
  Future<TrustRedeemResult?> redeemTrustToken(String token) => withAuthRetry(
    () => _client.messenger.redeemTrustToken(token: token),
    _session,
  );

  /// Отозвать мои инвайт-ссылки (старые перестают работать).
  Future<void> revokeInviteTokens() => withAuthRetry(
    () => _client.messenger.revokeInviteTokens(),
    _session,
  );

  /// **«Рядом»**: подтвердить близость с peer. Требует ВЗАИМНОГО тапа в
  /// окне 60с (BLE недоверенное). `matched=true` → взаимный контакт
  /// (можно открыть чат); `matched=false` → ждём ответный тап peer-а.
  Future<NearbyConfirmResult> confirmNearby(int peerMessengerUserId) =>
      withAuthRetry(
        () => _client.messenger.confirmNearby(
          peerMessengerUserId: peerMessengerUserId,
        ),
        _session,
      );
}
