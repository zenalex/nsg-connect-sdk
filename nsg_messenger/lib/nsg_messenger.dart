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

// Build-метка SDK (для показа версии в host-app и в баг-репортах).
export 'src/version.dart' show kNsgSdkBuild;

// Контракты интегратора и переиспользуемые типы.
export 'src/auth_token_provider.dart' show AuthTokenProvider, ErrorReporter;
export 'src/messenger_mode.dart';
export 'src/messenger_session_state.dart';
export 'src/theme/chatista_theme.dart' show ChatistaTheme;
// **issue #26**: единая настройка силы blur (--dart-define=GLASS_BLUR_PCT).
export 'src/theme/glass_blur.dart'
    show glassBlur, glassBlurSigma, kGlassBlurPercent;
// **issue #26**: рантайм-выключатель эффектов стекла (авто по устройству
// + ручной override). GlassBackdrop — обязательная обёртка blur-узлов.
// **issue #48**: kGlassOffBackplate — подложка панелей в off-режиме.
export 'src/theme/glass_effects.dart'
    show GlassEffects, GlassEffectsMode, GlassBackdrop, kGlassOffBackplate;
export 'src/theme/messenger_theme_scope.dart' show MessengerThemeScope;
// **issue #43**: непрозрачный фон для всплывашек — в Glass-темах `surface`
// прозрачный, и всё, что всплывает над лентой, надо красить явно.
export 'src/theme/overlay_surface.dart'
    show kOverlayBaseInk, kOverlaySheetSurface, kOverlaySurface;
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
// **TASK47**: слим-баннер «нет сети» (host кладёт над контентом chats/chat).
export 'src/widgets/messenger_connection_banner.dart'
    show MessengerConnectionBanner;

// **CHATista Glass design (2026-05-24)**: vivid multi-blob wallpaper
// widget. Host-app wraps app body in Stack with this at base; SDK
// widgets render on top with translucent palette (ChatistaTheme.glass*).
export 'src/widgets/glass_background.dart' show GlassBackground, GlassPalette;

// B16-extension: универсальный круглый аватар c fallback на gradient
// + инициалы. Используется в chat row / participants / settings.
export 'src/widgets/nsg_avatar_image.dart' show NsgAvatarImage;

// Demo mode fixtures (TASK22-Phase2 Chunk 2 PART C). Used by the
// `apps/spike_ui` theming sandbox + any host-app integration test
// that wants to render SDK widgets without booting the real backend.
export 'src/demo/demo_fixtures.dart' show DemoRoomFixture, DemoMessageFixture;

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

// **TASK58 (incoming webhooks / автопост статусов)**: API управления
// входящими webhook-ами (автопостами) комнаты + экран «Интеграции».
export 'src/integrations/nsg_messenger_integrations.dart'
    show NsgMessengerIntegrations;
export 'src/screens/integrations_screen.dart' show IntegrationsScreen;

// **TASK36 (боты)**: админка ботов (tenant-wide) — API + экран. Виден
// только админам из серверного `BOT_ADMIN_EMAILS`.
export 'src/admin/nsg_messenger_bots_admin.dart' show NsgMessengerBotsAdmin;
export 'src/bots/nsg_messenger_my_bots.dart' show NsgMessengerMyBots;
export 'src/screens/bots_admin_screen.dart' show BotsAdminScreen;
export 'src/screens/my_bots_screen.dart' show MyBotsScreen;

// **TASK78 п.3 (админка секретов тенантов)**: платформенное управление
// issued-token-режимом — API + экран. Виден только админам из серверного
// `PLATFORM_ADMIN_EMAILS`.
export 'src/admin/nsg_messenger_platform_admin.dart'
    show NsgMessengerPlatformAdmin;
export 'src/screens/platform_admin_screen.dart' show PlatformAdminScreen;

// **TASK60 (Connect Pulse — heartbeat-мониторинг)**: API дашборда мониторинга
// (папки/мониторы/правила/инциденты + realtime-стрим) + экран `PulseScreen`.
export 'src/pulse/nsg_messenger_pulse.dart' show NsgMessengerPulse;
// TASK63: организация контактов (alias / заметка / метки).
export 'src/contacts/nsg_messenger_contacts.dart' show NsgMessengerContacts;
// TASK52 итер.1: личная визитка (Contact Card).
export 'src/contact_card/nsg_messenger_contact_cards.dart'
    show NsgMessengerContactCards;
export 'src/contact_card/contact_card_view.dart'
    show ContactCardView, ContactCardSize;
export 'src/screens/contact_card_editor_screen.dart'
    show ContactCardEditorScreen;
export 'src/screens/pulse_screen.dart' show PulseScreen;

// Admin/moderation widgets (TASK29 Chunk 2).
export 'src/rooms/participant_action_sheet.dart'
    show showParticipantActionSheet, mapAdminError;
export 'src/rooms/role_badge.dart' show RoleBadge;

// Chat folders (TASK44 фаза 1.5). Клиентские авто-папки в модели
// «папка-как-строка». Модель и группировка (`buildFolders` /
// `buildRootRows`) экспортируются, чтобы host-app (Chatista) мог строить
// свой корневой список (строки-чаты + строки-папки) поверх SDK-логики.
export 'src/rooms/chat_folder_picker.dart' show showChatFolderPicker;
export 'src/rooms/chat_folder.dart'
    show
        ChatFolder,
        ChatFolderKind,
        ChatRootRow,
        ChatRoomRow,
        ChatFolderRow,
        buildFolders,
        buildRootRows,
        foldersVisible,
        isSupportInboxRoom,
        isDismissedSupportRoom,
        // **TASK68**: предикат «эта комната — раздел Избранного». Нужен
        // host-app-у, чтобы self-чаты не сыпались в его собственные
        // фильтры («Личные» / «Группы») наравне с настоящими чатами.
        isSavedRoom;

// Notification settings (TASK20-Phase2 Chunk 4).
export 'src/settings/nsg_messenger_settings.dart' show NsgMessengerSettings;

// **TASK49 (share-in)**: приём системного «Поделиться». Host-app маппит
// payload share-плагина в SDK-тип [SharedPayload] и зовёт
// `NsgMessenger.handleSharedPayload`. `SharedInboundItem` +
// [mapInboundToSharedPayload] — нейтральный маппер (тестируем без плагина).
export 'src/share/shared_payload.dart'
    show
        SharedPayload,
        SharedFile,
        SharedInboundItem,
        SharedInboundKind,
        mapInboundToSharedPayload;
export 'src/share/share_limits.dart' show SharedFileTooLargeException;

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
// **Issue #41**: координаты первоисточника пересланного сообщения. Публичны —
// host-app принимает `ForwardSource` в колбэке тапа по шапке «Переслано от X»
// и сам открывает нужный чат (кросс-чат навигация — забота хоста, не SDK).
export 'src/messages/forward_source.dart'
    show ForwardSource, resolveForwardSource;
// **TASK58**: структурированная статус-карточка (msgType `nsg.status_card`).
export 'src/messages/status_card_data.dart'
    show StatusCardData, StatusCardField, StatusCardLink, StatusCardLevel;
// **Редактирование альбома в композере**: модели диффа. Публичны, т.к.
// `MessagesController.editAlbum(ComposerAlbumEditResult)` — часть API.
export 'src/messages/composer_album_edit.dart'
    show ComposerAlbumImage, ComposerAlbumEdit, ComposerAlbumEditResult;
// MessagesRpc — visible-for-testing для host-app integration tests
// (подмена RPC слоя на in-memory fake без поднятия Serverpod).
export 'src/messages/messages_rpc.dart' show MessagesRpc, ClientMessagesRpc;

// **TASK46 (SDK)**: голосовые звонки 1:1. CallController (ChangeNotifier)
// + sealed CallState — готовы к UI-биндингу (overlay — отдельная задача).
// WebRtcAdapter/CallRpc экспортируются visible-for-testing (host-app /
// SDK-тесты подменяют flutter_webrtc и RPC-слой fake-ами).
export 'src/calls/call_controller.dart' show CallController, IdGenerator;
// **TASK46 (UI)**: глобальный хост оверлеев звонка. Host-app (Chatista/
// titan) оборачивает `MaterialApp.builder` в [CallOverlayHost] — он
// слушает `NsgMessenger.callController` и рисует входящий/исходящий/
// in-call overlay поверх всего (входящий ловится на любом экране).
export 'src/calls/call_overlay_host.dart' show CallOverlayHost, CallPeerRef;
// **Ringback (обратный сигнал каллеру)**: интерфейс плеера «гудков»
// исходящего звонка + стадии тона. Экспортируется как test-seam
// ([CallOverlayHost.ringbackPlayer] инжектится в тестах) и на случай,
// если host-app захочет свою реализацию.
export 'src/calls/call_ringback_player.dart'
    show CallRingbackPlayer, CallRingbackTone, JustAudioRingbackPlayer;
export 'src/calls/call_state.dart'
    show
        CallState,
        CallIdle,
        CallOutgoingRinging,
        CallIncomingRinging,
        CallConnecting,
        CallConnected,
        CallEnded,
        CallEndReason;
export 'src/calls/call_rpc.dart' show CallRpc, ClientCallRpc;
// **TASK51 итерация 1**: групповые (mesh) аудиозвонки. Контроллер +
// sealed ConferenceCallState — готовы к UI-биндингу (групповой overlay —
// следующий чанк). ConferenceRpc — test-seam, как CallRpc.
export 'src/calls/conference_call_controller.dart'
    show
        ConferenceCallController,
        ConferenceRoomInfo,
        ConferencePairCallId,
        kConferenceCallIdPrefix,
        kConferenceHeartbeatInterval;
// **TASK51 (UI)**: глобальный хост оверлеев ГРУППОВОГО звонка — host-app
// ставит его рядом с [CallOverlayHost] (Chatista: внутрь него, чтобы
// 1:1-оверлей при коллизии рисовался поверх).
export 'src/calls/conference_overlay_host.dart' show ConferenceOverlayHost;
export 'src/calls/conference_call_state.dart'
    show
        ConferenceCallState,
        ConferenceCallIdle,
        ConferenceIncomingRinging,
        ConferenceJoining,
        ConferenceActive,
        ConferenceCallEnded,
        ConferenceEndReason,
        ConferenceParticipantView,
        ConferencePairPhase;
export 'src/calls/conference_rpc.dart' show ConferenceRpc, ClientConferenceRpc;
export 'src/calls/webrtc_adapter.dart'
    show
        WebRtcAdapter,
        RtcPeerConnection,
        RtcMediaStream,
        MediaAudioTrack,
        RtcSdp,
        RtcIce,
        SdpType,
        RtcConnState,
        MicPermissionDeniedException;

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
        // Rate-limit (B6): resendVerification / requestPasswordReset могут
        // отвечать 429-подобной ошибкой с retryAfterSeconds — host-app
        // показывает «попробуйте через N секунд».
        RateLimitExceededException,
        // Room DTOs (TASK13).
        RoomSummary,
        // Страница комнат + курсор (issue #46) — нужна host-app-ам,
        // которые подключают полный синк своими RPC.
        RoomListPage,
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
        PushService,
        // Call DTOs (TASK46 SDK) — параметры/пейлоады сигналинга.
        CallEventType,
        CallIceCandidate,
        TurnCredentials,
        // Incoming webhook DTOs (TASK58) — модель + create/rotate result.
        IncomingWebhook,
        IncomingWebhookCreated,
        // Bot integration DTOs (TASK59) — self-service бот-интеграции: список
        // (`BotIntegrationView`) + create/rotate result (`BotIntegrationCreated`
        // с вложенными `Bot` / `WebhookSubscription`, секреты один раз).
        BotIntegrationView,
        BotIntegrationCreated,
        Bot,
        WebhookSubscription,
        // TASK78 п.3: платформенная админка секретов тенантов — статус
        // tenant-а и журнал операций с ключами.
        ConnectTenantStatus,
        ConnectKeyAuditEvent,
        // Pulse DTOs (TASK60) — дерево мониторинга + realtime-события.
        PulseFolder,
        PulseMonitor,
        PulseMonitorCreated,
        PulseAlertRule,
        PulseIncident,
        PulseEvent,
        // Push-test DTO (TASK61) — результат «Проверить пуш» (провайдеры +
        // число устройств + задержка).
        PushTestResult,
        // TASK62: пользовательские папки чатов.
        ChatFolderView,
        // TASK63: организация контактов.
        ContactProfileView,
        ContactLabel,
        // TASK52 итер.2: карточки-заявки + trust-обмен визитками.
        ContactRequestView,
        ContactRelation,
        ContactLinkSource,
        TrustTokenKind,
        TrustTokenIssued,
        TrustRedeemResult,
        NearbyConfirmResult;
