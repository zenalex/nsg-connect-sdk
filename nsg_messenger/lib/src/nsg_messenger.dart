import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import 'auth_token_provider.dart';
import 'demo/demo_fixtures.dart';
import 'demo/demo_runtime.dart';
import 'messages/messages_controller.dart';
import 'messages/messages_rpc.dart';
import 'messenger_mode.dart';
import 'messenger_runtime.dart';
import 'messenger_session_state.dart';
import 'push/push_token_provider.dart';
import 'rooms/nsg_messenger_rooms.dart';
import 'runtime/messenger_connection_state.dart';
import 'runtime/nsg_messenger_config.dart';
import 'screens/chat_screen.dart';
import 'screens/chats_list_screen.dart';
import 'screens/support_chat_screen.dart';
import 'session/auth_token_store.dart';
import 'theme/messenger_theme_scope.dart';
import 'theme/nsg_messenger_theme.dart';

/// Главный entry-point Flutter SDK NSG Connect.
///
/// Все методы статические — host-app не управляет lifecycle вручную,
/// SDK сам держит singleton (`MessengerRuntime`).
///
/// **На TASK11**: skeleton + публичный API. Реализация экранов —
/// TASK14 / TASK15 / TASK22.
class NsgMessenger {
  NsgMessenger._();

  /// Главный entry-point.
  ///
  /// `authTokenProvider` — обязательный callback, через который SDK
  /// получает свежий `MessengerAuthContext` (см. TASK12 для полной
  /// спецификации). SDK НЕ хранит customer accessToken; он каждый раз
  /// запрашивается у provider-а при init и при каждом refresh.
  /// `tokenStoreOverride` — visible-for-testing: позволяет подменить
  /// `flutter_secure_storage` на `InMemoryAuthTokenStore` в виджет- и
  /// integration-тестах host-app-а без MethodChannel-моков. В production
  /// host-app не передаёт — SDK использует `SecureAuthTokenStore`.
  static Future<void> init({
    required String apiBaseUrl,
    required AuthTokenProvider authTokenProvider,
    NsgMessengerTheme? theme,
    NsgMessengerLocale? locale,
    MessengerMode mode = MessengerMode.embeddedProduct,
    ErrorReporter? errorReporter,
    @visibleForTesting AuthTokenStore? tokenStoreOverride,
    PushTokenProvider? pushTokenProvider,
    String? productExternalKey,
    NsgMessengerConfig? config,
  }) {
    return MessengerRuntime.instance.init(
      apiBaseUrl: apiBaseUrl,
      authTokenProvider: authTokenProvider,
      theme: theme,
      locale: locale,
      mode: mode,
      errorReporter: errorReporter,
      tokenStoreOverride: tokenStoreOverride,
      pushTokenProvider: pushTokenProvider,
      productExternalKey: productExternalKey,
      config: config,
    );
  }

  /// **TASK22-Phase2 Chunk 2 PART C**: headless demo mode for design
  /// exploration. Bypasses real Client / WebSocket / RPC — backs SDK
  /// widgets with in-memory [DemoRoomFixture] / [DemoMessageFixture]
  /// lists so a designer can iterate on theming without a running
  /// backend.
  ///
  /// **NOT for production use.** Throws [StateError] if called twice
  /// or after [init].
  ///
  /// Limitations vs production [init]:
  ///   * `NsgMessenger.rooms.get(roomId)` returns the fixture details,
  ///     `list(...)` returns the fixture summaries; mutating RPCs
  ///     (mute/archive/leave/...) are no-ops.
  ///   * `NsgMessenger.userEventStream` never emits — demo runtime
  ///     has no realtime backend.
  ///   * Send/edit/delete/upload from ChatScreen throw
  ///     `UnimplementedError` (read-only). Wrap ChatScreen in
  ///     `readOnly: true` to hide MessageComposer entirely.
  ///   * `sessionStateStream()` immediately emits `active`.
  ///
  /// Customer integration walkthrough — use [init] instead.
  static Future<void> initDemo({
    required List<DemoRoomFixture> rooms,
    List<DemoMessageFixture> messages = const [],
    NsgMessengerTheme? theme,
    NsgMessengerLocale? locale,
    NsgMessengerConfig? config,
  }) async {
    final data = DemoRuntimeData.fromFixtures(
      rooms: rooms,
      messages: messages,
      selfMessengerUserId: -1,
      selfMatrixUserId: '@demo-self:demo',
    );
    await installDemoRuntime(
      data: data,
      theme: theme ?? NsgMessengerTheme.empty,
      locale: locale ?? const NsgMessengerLocale(),
      config: config,
    );
    // Stash the demo data on the runtime so `demoChatScreen` can
    // build a MessagesController without a real Client.
    _demoData = data;
  }

  /// **TASK22-Phase2 Chunk 2 PART C**: build a [ChatScreen] backed by
  /// the demo fixtures registered via [initDemo]. Wires up a
  /// `MessagesController` whose `MessagesRpc` reads from the in-memory
  /// fixture map and passes it via `controllerOverride` so the
  /// production code path (which needs `MessengerRuntime.client`) is
  /// bypassed.
  ///
  /// `readOnly: true` hides the `MessageComposer` — recommended for
  /// demo use since send is disabled at the RPC layer.
  static Widget demoChatScreen({
    required int roomId,
    bool readOnly = true,
  }) {
    final data = _demoData;
    if (data == null) {
      throw StateError(
        'NsgMessenger.demoChatScreen() called before initDemo(). '
        'Call NsgMessenger.initDemo(rooms: ...) first.',
      );
    }
    final runtime = MessengerRuntime.instance;
    final controller = MessagesController(
      roomId: roomId,
      rpc: buildDemoMessagesRpc(data),
      events: runtime.eventBus.events,
      selfMessengerUserId: data.selfMessengerUserId,
      selfMatrixUserId: data.selfMatrixUserId,
    );
    return MessengerThemeScope(
      theme: runtime.theme,
      child: ChatScreen(
        roomId: roomId,
        // ignore: invalid_use_of_visible_for_testing_member
        controllerOverride: controller,
        readOnly: readOnly,
      ),
    );
  }

  /// **TASK22-Phase2 Chunk 2 PART C**: cached demo fixture bundle for
  /// [demoChatScreen]. Reset by [dispose] and overwritten by any
  /// subsequent [initDemo] (which the runtime guard already rejects).
  static DemoRuntimeData? _demoData;

  /// Принудительно сбросить кэш и заново получить контекст у provider-а.
  /// Нужно после logout/login в host-app.
  static Future<void> reauthenticate() =>
      MessengerRuntime.instance.reauthenticate();

  static Future<void> dispose() async {
    _demoData = null;
    await MessengerRuntime.instance.dispose();
  }

  /// Stream `MessengerSessionState`-ов: `uninitialised → refreshing →
  /// active`. Host-app может показывать на основе этого баннер
  /// "соединение восстанавливается" / "session истекла".
  static Stream<MessengerSessionState> sessionStateStream() =>
      MessengerRuntime.instance.stateStream;

  /// **TASK20 followup (a)**: stream `MessengerConnectionState`-ов
  /// (`healthy → reconnecting → disconnected`). Separate axis from
  /// `sessionStateStream` — transport (WS) health, не auth/login.
  ///
  /// Token cache **НЕ trogается** при transport failures — auth
  /// invalidation отдельный axis. Host-app может embed
  /// [ConnectionStateIndicator] widget в AppBar чтобы рисовать
  /// traffic-light circle.
  static Stream<MessengerConnectionState> connectionStateStream() =>
      MessengerRuntime.instance.connectionStateStream;

  /// Current value of [connectionStateStream]. Default — `healthy`.
  static MessengerConnectionState get connectionState =>
      MessengerRuntime.instance.connectionState;

  /// **TASK20 followup (a)**: запросить immediate reconnect bus's WS.
  /// No-op если bus уже healthy. Идемпотентно. Полезно для host-app
  /// если он сам хочет принудительно проверить здоровье (например при
  /// tap по [ConnectionStateIndicator]).
  static void forceReconnect() =>
      MessengerRuntime.instance.eventBus.forceReconnect();

  /// API для работы с комнатами: list/get/createDirect/createGroup/
  /// getOrCreateProductRoom/openSupportChat. См. [NsgMessengerRooms].
  /// Включает in-memory cache 30s + invalidation на realtime events.
  static NsgMessengerRooms get rooms => MessengerRuntime.instance.rooms;

  /// Текущая активная сессия — `messengerUserId`, `matrixUserId`,
  /// `displayName`, `avatarUrl`, и `sessionToken`. Host-app использует
  /// для отображения профиля и для self-vs-peer вычислений.
  ///
  /// Throws `StateError` если session ещё не установлена (init не
  /// завершён, либо token expired без re-auth). Host-app может
  /// подписаться на [sessionStateStream] чтобы знать состояние.
  static MessengerSession get session => MessengerRuntime.instance.session;

  /// **Avatar upload (B16-extension)**: загрузить аватар текущего юзера.
  ///
  /// Server:
  ///   1. Validate MIME (image/*).
  ///   2. Upload bytes в Matrix media → mxc:// URL.
  ///   3. Save в `MessengerUser.avatarUrl` (DB).
  ///   4. Best-effort `setAvatar` на Matrix profile (через Synapse Admin
  ///      API) — чтобы другие matrix-клиенты тоже увидели.
  ///
  /// Возвращает `mxcUrl`. Host-app после этого может:
  ///   * показать новый аватар у себя в profile screen-е;
  ///   * `rooms.invalidate()` чтобы при следующем listRooms RoomSummary
  ///     подтянул свежий avatarUrl (server computes для direct chats).
  ///
  /// Throws `MatrixUnconfiguredException` если matrix-bridge не настроен
  /// (например, в demo-режиме / тестах). `ArgumentError` если MIME не
  /// image/*. На прочие ошибки upload — re-throw от Serverpod / Matrix.
  static Future<String> uploadUserAvatar({
    required Uint8List bytes,
    required String mimeType,
  }) {
    return MessengerRuntime.instance.client.messenger.uploadUserAvatar(
      bytes: ByteData.sublistView(bytes),
      mimeType: mimeType,
    );
  }

  /// Realtime-стрим **всех** событий текущего юзера. На MVP TASK17 это
  /// `messageCreated` + (TASK17 Chunk 2 расширит membership/state). UI
  /// обычно использует `roomStream(roomId)` для конкретной комнаты;
  /// `userEventStream` нужен для cross-room-логики (badges,
  /// foreground suppression, и пр.).
  ///
  /// Auto-reconnect on token rotation встроен через
  /// [MessengerEventBus] — host-app не делает ничего, события
  /// продолжают приходить под новым токеном.
  ///
  /// Геттер (а не метод-без-args) для consistency с [rooms]
  /// (см. ревью 8336e2e #2).
  static Stream<MessengerEvent> get userEventStream =>
      MessengerRuntime.instance.eventBus.events;

  /// Realtime-стрим событий конкретной комнаты. Локальный фильтр над
  /// общим `userEventStream` — один long-poll к серверу независимо от
  /// количества открытых чатов (см. ревью TASK17 Q2).
  static Stream<MessengerEvent> roomStream(int roomId) =>
      MessengerRuntime.instance.eventBus.roomStream(roomId);

  /// Создать [MessagesController] для одной комнаты (TASK15 Chunk 1).
  ///
  /// Lifecycle: per-ChatScreen — `init()` в `initState`, `dispose()` в
  /// `dispose`. Глобального cache контроллеров нет: повторное открытие
  /// комнаты создаёт свежий controller с full-reload первой страницы.
  /// (Persistent pre-fetch для push notifications — TASK20.)
  ///
  /// Тесты host-app-а могут передать [rpcOverride] для подмены RPC
  /// слоя без поднятия Serverpod-клиента.
  static MessagesController messagesControllerFor(
    int roomId, {
    @visibleForTesting MessagesRpc? rpcOverride,
  }) {
    final runtime = MessengerRuntime.instance;
    return MessagesController(
      roomId: roomId,
      rpc: rpcOverride ?? ClientMessagesRpc(runtime.client),
      events: runtime.eventBus.events,
      selfMessengerUserId: runtime.session.messengerUserId,
      selfMatrixUserId: runtime.session.matrixUserId,
    );
  }

  /// Hook для host-app `WidgetsBindingObserver.didChangeAppLifecycleState`.
  /// **TASK20** реализует: при `paused`/`detached` SDK закрывает
  /// underlying long-poll (foreground suppression), при `resumed` —
  /// переоткрывает. На TASK17 — no-op stub, чтобы host-app мог
  /// подключить observer прямо сейчас без последующего breaking change.
  static void onAppLifecycleChanged(AppLifecycleState state) =>
      MessengerRuntime.instance.eventBus.onAppLifecycleChanged(state);

  // ----- Виджеты -----

  /// Виджет списка чатов. Mode задаётся в `init()`, но можно
  /// переопределить точечно (для compactWidget).
  ///
  /// Если в `init(theme: ...)` host-app передал не-empty
  /// `NsgMessengerTheme`, widget автоматически оборачивается в
  /// [MessengerThemeScope] для injection theme overrides
  /// (ColorScheme + bubble/tile tokens). См. TASK22 Chunk 2.
  static Widget chatsListView({MessengerMode? mode}) {
    final runtime = MessengerRuntime.instance;
    return MessengerThemeScope(
      theme: runtime.theme,
      child: ChatsListScreen(mode: mode ?? runtime.mode),
    );
  }

  // ----- Навигация (host-app сам решает, как push-ить) -----

  /// Открыть конкретную комнату. ChatScreen route оборачивается в
  /// [MessengerThemeScope] для consistency с `chatsListView`.
  static Future<void> openRoom(BuildContext context, int roomId) async {
    final theme = MessengerRuntime.instance.theme;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MessengerThemeScope(
          theme: theme,
          child: ChatScreen(roomId: roomId),
        ),
      ),
    );
  }

  /// Открыть support-chat для заданного контекста (id заказа,
  /// тикета и т.д.).
  static Future<void> openSupportChat(
    BuildContext context, {
    required String contextId,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SupportChatScreen(contextId: contextId),
      ),
    );
  }

  /// Открыть чат, привязанный к сущности продукта (см. ТЗ §13).
  /// На TASK11 — заглушка; getOrCreateProductRoom приходит в TASK13.
  static Future<void> openProductRoom(
    BuildContext context, {
    required String productKey,
    required String entityType,
    required String entityId,
  }) async {
    throw UnimplementedError(
      'openProductRoom приходит в TASK13 (RoomService).',
    );
  }
}
