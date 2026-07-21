import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../messenger_runtime.dart';
import '../session/auth_retry.dart';
import '../session/messenger_session_manager.dart';

/// **TASK52 итер.1**: SDK-фасад личных визиток (Contact Card).
///
/// Чужие карточки — [get] с per-user TTL-кэшем (5 мин; карточки меняются
/// редко, updatedAt на сервере — задел под etag итерацией позже). Для
/// экрана входящего звонка — [prefetch] с жёстким таймаутом: звонок
/// НИКОГДА не ждёт визитку (§3A.6 спеки), не успела — обычный вид.
class NsgMessengerContactCards {
  NsgMessengerContactCards.attach(Client client) : _client = client;

  final Client _client;

  MessengerSessionManager get _session =>
      MessengerRuntime.instance.sessionManager;

  static const Duration cacheTtl = Duration(minutes: 5);

  /// Таймаут префетча на звонке (§4 спеки: ~1с, иначе fallback).
  static const Duration callPrefetchTimeout = Duration(seconds: 1);

  final Map<int, _CachedCard> _cache = {};

  /// Визитка пользователя глазами текущего (contacts-only поля сервер
  /// уже вырезал). null = визитки нет. Кэш per-user TTL 5 мин.
  Future<ContactCardInfo?> get(int messengerUserId) async {
    final hit = _cache[messengerUserId];
    if (hit != null && DateTime.now().difference(hit.at) < cacheTtl) {
      return hit.info;
    }
    final fresh = await withAuthRetry(
      () => _client.messenger.getContactCard(
        messengerUserId: messengerUserId,
      ),
      _session,
    );
    _cache[messengerUserId] = _CachedCard(fresh, DateTime.now());
    return fresh;
  }

  /// Кэш-hit без сети (для синхронного рендера звонка, когда prefetch
  /// уже прогрел кэш). null = в кэше нет (или протухло).
  ContactCardInfo? peek(int messengerUserId) {
    final hit = _cache[messengerUserId];
    if (hit == null || DateTime.now().difference(hit.at) >= cacheTtl) {
      return null;
    }
    return hit.info;
  }

  /// Префетч для экрана звонка: [get] с таймаутом [callPrefetchTimeout].
  /// Ошибки/таймаут глотаются — карточка не в критическом пути звонка.
  Future<ContactCardInfo?> prefetch(int messengerUserId) async {
    try {
      return await get(messengerUserId).timeout(callPrefetchTimeout);
    } catch (_) {
      return null;
    }
  }

  /// Своя карточка целиком (включая contactsOnlyFields) — для редактора.
  Future<ContactCard?> getMy() => withAuthRetry(
    () => _client.messenger.getMyContactCard(),
    _session,
  );

  /// Сохранить свою карточку (upsert). Сбрасывает свой кэш — профиль
  /// увидит свежую версию.
  Future<ContactCard> setMy(ContactCard card) async {
    final saved = await withAuthRetry(
      () => _client.messenger.setMyContactCard(card: card),
      _session,
    );
    _cache.remove(saved.messengerUserId);
    return saved;
  }

  /// Удалить свою карточку. Идемпотентно.
  Future<void> deleteMy() async {
    await withAuthRetry(
      () => _client.messenger.deleteMyContactCard(),
      _session,
    );
    _cache.clear();
  }

  /// Сброс кэша (logout / смена аккаунта).
  void invalidate() => _cache.clear();
}

class _CachedCard {
  const _CachedCard(this.info, this.at);
  final ContactCardInfo? info; // null — «визитки нет» тоже кэшируется
  final DateTime at;
}
