/// nsg_messenger — Flutter SDK для встраивания мессенджера Chatista
/// (платформа NSG Connect, Serverpod + Matrix).
///
/// Барьер с публичным API. Внутренние типы (`MessengerRuntime`,
/// `MessengerAuthKeyProvider`, `MessengerSessionManager`) **не**
/// экспортируются — они реализационные детали SDK.
///
/// См. README пакета и `docs/tasks/TASK11.md`, `TASK12.md`.
library;

// Главный entry-point.
export 'src/nsg_messenger.dart';

// Контракты интегратора и переиспользуемые типы.
export 'src/auth_token_provider.dart' show AuthTokenProvider, ErrorReporter;
export 'src/messenger_mode.dart';
export 'src/messenger_session_state.dart';
export 'src/theme/chatista_theme.dart' show ChatistaTheme;
export 'src/theme/messenger_theme_scope.dart' show MessengerThemeScope;
export 'src/theme/nsg_messenger_theme.dart';

// Runtime config (TASK22-Phase2 Chunk 1-B). Behavior knobs separately
// from NsgMessengerTheme — scroll thresholds, pagination sizes, etc.
export 'src/runtime/nsg_messenger_config.dart'
    show NsgMessengerConfig, NsgScrollThresholds;

// **TASK20 followup (a)**: transport health axis (separate from
// MessengerSessionState which is auth/login). Stream + tiny traffic-
// light indicator widget host-app может embed-нуть в AppBar.
export 'src/runtime/messenger_connection_state.dart'
    show MessengerConnectionState;
export 'src/widgets/connection_state_indicator.dart'
    show ConnectionStateIndicator;

// **CHATista Glass design (2026-05-24)**: vivid multi-blob wallpaper
// widget. Host-app wraps app body in Stack with this at base; SDK
// widgets render on top with translucent palette (ChatistaTheme.glass*).
export 'src/widgets/glass_background.dart'
    show GlassBackground, GlassPalette;

// B16-extension: универсальный круглый аватар c fallback на gradient
// + инициалы. Используется в chat row / participants / settings.
export 'src/widgets/nsg_avatar_image.dart' show NsgAvatarImage;

// Demo mode fixtures (TASK22-Phase2 Chunk 2 PART C). Used by the
// `apps/spike_ui` theming sandbox + any host-app integration test
// that wants to render SDK widgets without booting the real backend.
export 'src/demo/demo_fixtures.dart'
    show DemoRoomFixture, DemoMessageFixture;

// Visible-for-testing: AuthTokenStore + InMemoryAuthTokenStore нужны
// host-app-у, который хочет писать виджет/integration-тесты SDK без
// MethodChannel-моков на flutter_secure_storage.
export 'src/session/auth_token_store.dart'
    show AuthTokenStore, InMemoryAuthTokenStore, StoredMessengerSession;

// **TASK20 followup (b)**: stale-token self-healing helpers. Host-app
// и SDK-internal code оборачивает критические RPC в [withAuthRetry],
// чтобы при server-side revoke-е токена прозрачно обновиться через
// AuthTokenProvider и отретраить. [isAuthInvalidation] полезен, если
// host-app хочет сам решать на типизированной auth-ошибке (например,
// показать toast).
export 'src/session/auth_retry.dart' show withAuthRetry, isAuthInvalidation;

// Rooms API (TASK13 Chunk 2).
export 'src/rooms/nsg_messenger_rooms.dart' show NsgMessengerRooms;

// Admin/moderation widgets (TASK29 Chunk 2).
export 'src/rooms/participant_action_sheet.dart'
    show showParticipantActionSheet, mapAdminError;
export 'src/rooms/role_badge.dart' show RoleBadge;

// Notification settings (TASK20-Phase2 Chunk 4).
export 'src/settings/nsg_messenger_settings.dart' show NsgMessengerSettings;

// i18n (TASK22 Chunk 1). Host-app должен добавить
// `NsgL10n.delegate` в свой `MaterialApp.localizationsDelegates`
// и `NsgL10n.supportedLocales` в `supportedLocales` чтобы SDK
// widgets рендерили локализованные строки.
export 'src/i18n/generated/nsg_l10n.dart' show NsgL10n;

// Push API (TASK20 Chunk 3).
// Public PushTokenProvider interface + InMemoryPushTokenProvider для
// embed-mode без push / тестов host-app. Production-имплементация
// (FirebasePushTokenProvider) — в отдельном пакете `nsg_messenger_push`.
export 'src/push/push_token_provider.dart'
    show PushTokenProvider, InMemoryPushTokenProvider, DeviceInfo;

// Messages API (TASK15 Chunk 1).
export 'src/messages/messages_controller.dart' show MessagesController;
export 'src/messages/messages_state.dart'
    show MessagesState, MessagesLoading, MessagesReady, MessagesError;
export 'src/messages/chat_message.dart'
    show ChatMessage, ChatMessageStatus, ReactionGroup;
// MessagesRpc — visible-for-testing для host-app integration tests
// (подмена RPC слоя на in-memory fake без поднятия Serverpod).
export 'src/messages/messages_rpc.dart' show MessagesRpc, ClientMessagesRpc;

// Re-export Serverpod-моделей, которые встречаются в публичных API
// (MessengerAuthContext, MessengerSession, IdentityProvider). Так
// host-app-у не нужно отдельно тянуть `nsg_connect_client`.
export 'package:nsg_connect_client/nsg_connect_client.dart'
    show
        IdentityProvider,
        MessengerAuthContext,
        MessengerSession,
        MessengerNotAuthenticatedException,
        InvalidTokenException,
        // Email auth (signUp / signIn / signOut endpoint DTOs).
        EmailAuthException,
        // Room DTOs (TASK13).
        RoomSummary,
        RoomDetails,
        RoomParticipant,
        RoomMemberRole,
        RoomType,
        RoomState,
        PeerUnavailableException,
        RoomUnavailableException,
        ProductNotFoundForCallerException,
        // Message + Event DTOs (TASK09 + TASK17 + TASK15).
        MessengerMessage,
        MessengerMessageListPage,
        MessengerEvent,
        MessengerEventType,
        // Push DTOs (TASK20 Chunk 3).
        DeviceRegistration,
        DevicePlatform,
        PushService;
