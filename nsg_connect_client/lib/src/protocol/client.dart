/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i1;
import 'package:serverpod_client/serverpod_client.dart' as _i2;
import 'dart:async' as _i3;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i4;
import 'package:nsg_connect_client/src/protocol/webhook_subscription.dart'
    as _i5;
import 'package:nsg_connect_client/src/protocol/webhook_delivery.dart' as _i6;
import 'package:nsg_connect_client/src/protocol/bot.dart' as _i7;
import 'package:nsg_connect_client/src/protocol/bot_audit_event.dart' as _i8;
import 'package:nsg_connect_client/src/protocol/room_summary.dart' as _i9;
import 'package:nsg_connect_client/src/protocol/bot_integration_created.dart'
    as _i10;
import 'package:nsg_connect_client/src/protocol/bot_integration_view.dart'
    as _i11;
import 'package:nsg_connect_client/src/protocol/connect_tenant_status.dart'
    as _i12;
import 'package:nsg_connect_client/src/protocol/connect_key_audit_event.dart'
    as _i13;
import 'package:nsg_connect_client/src/protocol/connect_issued_token_result.dart'
    as _i14;
import 'package:nsg_connect_client/src/protocol/messenger_auth_context.dart'
    as _i15;
import 'package:nsg_connect_client/src/protocol/enums/device_platform.dart'
    as _i16;
import 'package:nsg_connect_client/src/protocol/device_session_info.dart'
    as _i17;
import 'package:nsg_connect_client/src/protocol/incoming_webhook.dart' as _i18;
import 'package:nsg_connect_client/src/protocol/incoming_webhook_created.dart'
    as _i19;
import 'package:nsg_connect_client/src/protocol/messenger_session.dart' as _i20;
import 'package:nsg_connect_client/src/protocol/messenger_message.dart' as _i21;
import 'package:nsg_connect_client/src/protocol/attachment_ref.dart' as _i22;
import 'package:nsg_connect_client/src/protocol/task_link.dart' as _i23;
import 'package:nsg_connect_client/src/protocol/enums/call_event_type.dart'
    as _i24;
import 'package:nsg_connect_client/src/protocol/call_ice_candidate.dart'
    as _i25;
import 'package:nsg_connect_client/src/protocol/turn_credentials.dart' as _i26;
import 'package:nsg_connect_client/src/protocol/messenger_event.dart' as _i27;
import 'package:nsg_connect_client/src/protocol/call_history_entry.dart'
    as _i28;
import 'package:nsg_connect_client/src/protocol/conference_state.dart' as _i29;
import 'package:nsg_connect_client/src/protocol/enums/room_member_role.dart'
    as _i30;
import 'package:nsg_connect_client/src/protocol/room_participant.dart' as _i31;
import 'dart:typed_data' as _i32;
import 'package:nsg_connect_client/src/protocol/attachment_bytes.dart' as _i33;
import 'package:nsg_connect_client/src/protocol/messenger_message_list_page.dart'
    as _i34;
import 'package:nsg_connect_client/src/protocol/device_registration.dart'
    as _i35;
import 'package:nsg_connect_client/src/protocol/enums/push_service.dart'
    as _i36;
import 'package:nsg_connect_client/src/protocol/enums/room_state.dart' as _i37;
import 'package:nsg_connect_client/src/protocol/room_list_page.dart' as _i38;
import 'package:nsg_connect_client/src/protocol/room_details.dart' as _i39;
import 'package:nsg_connect_client/src/protocol/enums/room_type.dart' as _i40;
import 'package:nsg_connect_client/src/protocol/ticket_view.dart' as _i41;
import 'package:nsg_connect_client/src/protocol/presence_info.dart' as _i42;
import 'package:nsg_connect_client/src/protocol/chat_folder_view.dart' as _i43;
import 'package:nsg_connect_client/src/protocol/contact_relation.dart' as _i44;
import 'package:nsg_connect_client/src/protocol/contact_request_view.dart'
    as _i45;
import 'package:nsg_connect_client/src/protocol/trust_token_issued.dart'
    as _i46;
import 'package:nsg_connect_client/src/protocol/enums/trust_token_kind.dart'
    as _i47;
import 'package:nsg_connect_client/src/protocol/trust_redeem_result.dart'
    as _i48;
import 'package:nsg_connect_client/src/protocol/nearby_confirm_result.dart'
    as _i49;
import 'package:nsg_connect_client/src/protocol/contact_card_info.dart' as _i50;
import 'package:nsg_connect_client/src/protocol/contact_card.dart' as _i51;
import 'package:nsg_connect_client/src/protocol/contact_profile_view.dart'
    as _i52;
import 'package:nsg_connect_client/src/protocol/contact_label.dart' as _i53;
import 'package:nsg_connect_client/src/protocol/contact_label_assignment.dart'
    as _i54;
import 'package:nsg_connect_client/src/protocol/support_team_view.dart' as _i55;
import 'package:nsg_connect_client/src/protocol/enums/support_team_role.dart'
    as _i56;
import 'package:nsg_connect_client/src/protocol/product_object_room.dart'
    as _i57;
import 'package:nsg_connect_client/src/protocol/escalation_result.dart' as _i58;
import 'package:nsg_connect_client/src/protocol/product.dart' as _i59;
import 'package:nsg_connect_client/src/protocol/presence_state.dart' as _i60;
import 'package:nsg_connect_client/src/protocol/notification_settings.dart'
    as _i61;
import 'package:nsg_connect_client/src/protocol/push_test_result.dart' as _i62;
import 'package:nsg_connect_client/src/protocol/profile_translation.dart'
    as _i63;
import 'package:nsg_connect_client/src/protocol/product_notification_send_result.dart'
    as _i64;
import 'package:nsg_connect_client/src/protocol/pulse_event.dart' as _i65;
import 'package:nsg_connect_client/src/protocol/pulse_folder.dart' as _i66;
import 'package:nsg_connect_client/src/protocol/pulse_monitor.dart' as _i67;
import 'package:nsg_connect_client/src/protocol/pulse_monitor_created.dart'
    as _i68;
import 'package:nsg_connect_client/src/protocol/pulse_alert_rule.dart' as _i69;
import 'package:nsg_connect_client/src/protocol/pulse_incident.dart' as _i70;
import 'package:nsg_connect_client/src/protocol/task_manager_config.dart'
    as _i71;
import 'package:nsg_connect_client/src/protocol/greetings/greeting.dart'
    as _i72;
import 'protocol.dart' as _i73;

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// {@category Endpoint}
class EndpointEmailIdp extends _i1.EndpointEmailIdpBase {
  EndpointEmailIdp(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  /// Logs in the user and returns a new session.
  ///
  /// Throws an [EmailAccountLoginException] in case of errors, with reason:
  /// - [EmailAccountLoginExceptionReason.invalidCredentials] if the email or
  ///   password is incorrect.
  /// - [EmailAccountLoginExceptionReason.tooManyAttempts] if there have been
  ///   too many failed login attempts.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _i3.Future<_i4.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'emailIdp',
    'login',
    {
      'email': email,
      'password': password,
    },
  );

  /// Starts the registration for a new user account with an email-based login
  /// associated to it.
  ///
  /// Upon successful completion of this method, an email will have been
  /// sent to [email] with a verification link, which the user must open to
  /// complete the registration.
  ///
  /// Always returns a account request ID, which can be used to complete the
  /// registration. If the email is already registered, the returned ID will not
  /// be valid.
  @override
  _i3.Future<_i2.UuidValue> startRegistration({required String email}) =>
      caller.callServerEndpoint<_i2.UuidValue>(
        'emailIdp',
        'startRegistration',
        {'email': email},
      );

  /// Verifies an account request code and returns a token
  /// that can be used to complete the account creation.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if no request exists
  ///   for the given [accountRequestId] or [verificationCode] is invalid.
  @override
  _i3.Future<String> verifyRegistrationCode({
    required _i2.UuidValue accountRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyRegistrationCode',
    {
      'accountRequestId': accountRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a new account registration, creating a new auth user with a
  /// profile and attaching the given email account to it.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [registrationToken]
  ///   is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  ///
  /// Returns a session for the newly created user.
  @override
  _i3.Future<_i4.AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'emailIdp',
    'finishRegistration',
    {
      'registrationToken': registrationToken,
      'password': password,
    },
  );

  /// Requests a password reset for [email].
  ///
  /// If the email address is registered, an email with reset instructions will
  /// be send out. If the email is unknown, this method will have no effect.
  ///
  /// Always returns a password reset request ID, which can be used to complete
  /// the reset. If the email is not registered, the returned ID will not be
  /// valid.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to request a password reset.
  ///
  @override
  _i3.Future<_i2.UuidValue> startPasswordReset({required String email}) =>
      caller.callServerEndpoint<_i2.UuidValue>(
        'emailIdp',
        'startPasswordReset',
        {'email': email},
      );

  /// Verifies a password reset code and returns a finishPasswordResetToken
  /// that can be used to finish the password reset.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to verify the password reset.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// If multiple steps are required to complete the password reset, this endpoint
  /// should be overridden to return credentials for the next step instead
  /// of the credentials for setting the password.
  @override
  _i3.Future<String> verifyPasswordResetCode({
    required _i2.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyPasswordResetCode',
    {
      'passwordResetRequestId': passwordResetRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a password reset request by setting a new password.
  ///
  /// The [verificationCode] returned from [verifyPasswordResetCode] is used to
  /// validate the password reset request.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.policyViolation] if the new
  ///   password does not comply with the password policy.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _i3.Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) => caller.callServerEndpoint<void>(
    'emailIdp',
    'finishPasswordReset',
    {
      'finishPasswordResetToken': finishPasswordResetToken,
      'newPassword': newPassword,
    },
  );

  @override
  _i3.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'emailIdp',
    'hasAccount',
    {},
  );
}

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
/// {@category Endpoint}
class EndpointJwtRefresh extends _i4.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// Can throw the following exceptions:
  /// -[RefreshTokenMalformedException]: refresh token is malformed and could
  ///   not be parsed. Not expected to happen for tokens issued by the server.
  /// -[RefreshTokenNotFoundException]: refresh token is unknown to the server.
  ///   Either the token was deleted or generated by a different server.
  /// -[RefreshTokenExpiredException]: refresh token has expired. Will happen
  ///   only if it has not been used within configured `refreshTokenLifetime`.
  /// -[RefreshTokenInvalidSecretException]: refresh token is incorrect, meaning
  ///   it does not refer to the current secret refresh token. This indicates
  ///   either a malfunctioning client or a malicious attempt by someone who has
  ///   obtained the refresh token. In this case the underlying refresh token
  ///   will be deleted, and access to it will expire fully when the last access
  ///   token is elapsed.
  ///
  /// This endpoint is unauthenticated, meaning the client won't include any
  /// authentication information with the call.
  @override
  _i3.Future<_i4.AuthSuccess> refreshAccessToken({
    required String refreshToken,
  }) => caller.callServerEndpoint<_i4.AuthSuccess>(
    'jwtRefresh',
    'refreshAccessToken',
    {'refreshToken': refreshToken},
    authenticated: false,
  );
}

/// **TASK35**: admin-only управление outbound-webhook подписками.
/// КАЖДЫЙ метод gate-ится через [requireMessengerUserId] + email caller-а
/// в allowlist-е env `WEBHOOK_ADMIN_EMAILS` (CSV). Unauthorized →
/// [MessengerNotAuthenticatedException] (anti-enumeration: тот же
/// exception, что и для unauthenticated; не раскрываем существование
/// endpoint-а).
///
/// Резолв tenant/product — по externalKey (`nsg` / `chatista`), как в
/// клиентском MessengerAuthContext. URL-ы валидируются [WebhookUrlValidator]
/// на create/update (SSRF-гард).
/// {@category Endpoint}
class EndpointAdminWebhook extends _i2.EndpointRef {
  EndpointAdminWebhook(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'adminWebhook';

  /// Список подписок tenant-а (опц. фильтр по продукту).
  _i3.Future<List<_i5.WebhookSubscription>> listSubscriptions({
    required String tenantExternalKey,
    String? productExternalKey,
  }) => caller.callServerEndpoint<List<_i5.WebhookSubscription>>(
    'adminWebhook',
    'listSubscriptions',
    {
      'tenantExternalKey': tenantExternalKey,
      'productExternalKey': productExternalKey,
    },
  );

  /// Создать подписку. Валидирует url (SSRF), генерит секрет если не задан.
  _i3.Future<_i5.WebhookSubscription> createSubscription({
    required String tenantExternalKey,
    String? productExternalKey,
    required String url,
    required String eventTypes,
    String? secret,
    String? description,
  }) => caller.callServerEndpoint<_i5.WebhookSubscription>(
    'adminWebhook',
    'createSubscription',
    {
      'tenantExternalKey': tenantExternalKey,
      'productExternalKey': productExternalKey,
      'url': url,
      'eventTypes': eventTypes,
      'secret': secret,
      'description': description,
    },
  );

  /// Обновить подписку. Re-validate url если меняется. `enabled=true`
  /// сбрасывает circuit-breaker (failureCount=0, disabledAt=null).
  _i3.Future<_i5.WebhookSubscription> updateSubscription({
    required int id,
    String? url,
    String? eventTypes,
    bool? enabled,
    String? secret,
    String? description,
  }) => caller.callServerEndpoint<_i5.WebhookSubscription>(
    'adminWebhook',
    'updateSubscription',
    {
      'id': id,
      'url': url,
      'eventTypes': eventTypes,
      'enabled': enabled,
      'secret': secret,
      'description': description,
    },
  );

  /// Удалить подписку (cascade удаляет её deliveries).
  _i3.Future<void> deleteSubscription({required int id}) =>
      caller.callServerEndpoint<void>(
        'adminWebhook',
        'deleteSubscription',
        {'id': id},
      );

  /// Тестовая доставка: вставляет `webhook.test` delivery и выполняет
  /// ОДНУ попытку inline, возвращая итоговую [WebhookDelivery].
  _i3.Future<_i6.WebhookDelivery> testDelivery({required int id}) =>
      caller.callServerEndpoint<_i6.WebhookDelivery>(
        'adminWebhook',
        'testDelivery',
        {'id': id},
      );

  /// Журнал/DLQ доставок по подписке (новые сверху).
  _i3.Future<List<_i6.WebhookDelivery>> listDeliveries({
    required int subscriptionId,
    required int limit,
  }) => caller.callServerEndpoint<List<_i6.WebhookDelivery>>(
    'adminWebhook',
    'listDeliveries',
    {
      'subscriptionId': subscriptionId,
      'limit': limit,
    },
  );
}

/// **TASK36**: admin-only управление ботами (программными клиентами
/// мессенджера). КАЖДЫЙ метод gate-ится через [requireMessengerUserId] +
/// email caller-а в allowlist-е env `BOT_ADMIN_EMAILS` (CSV). Unauthorized
/// → [MessengerNotAuthenticatedException] (anti-enumeration: тот же
/// exception, что и для unauthenticated; не раскрываем существование
/// endpoint-а). Зеркалит `AdminWebhookEndpoint._gate`.
///
/// Резолв tenant/product — по externalKey (`nsg` / `chatista`).
///
/// `createBot` возвращает [Bot] с `accessToken` — он показывается админу
/// ОДИН раз (далее токен в БД, но это long-lived bot-credential).
/// {@category Endpoint}
class EndpointBotAdmin extends _i2.EndpointRef {
  EndpointBotAdmin(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'botAdmin';

  /// **TASK36 (admin UI)**: доступна ли caller-у админка ботов. Нужен
  /// клиенту, чтобы не показывать пункт меню тому, кому все методы всё
  /// равно ответят отказом. Не гейтится: авторизацию по-прежнему решает
  /// сервер на каждом методе, а сам факт «я не админ» ничего не раскрывает.
  _i3.Future<bool> isBotAdmin() => caller.callServerEndpoint<bool>(
    'botAdmin',
    'isBotAdmin',
    {},
  );

  /// Создать бота. `capabilities` — CSV (`send_messages,manage_room`).
  /// Возвращаемый [Bot] содержит `accessToken` — показать админу ОДИН раз.
  ///
  /// **Issue #49**: [discoverable] — виден ли бот в поиске. Дефолт false:
  /// публичность бота — осознанный выбор владельца, а не побочный эффект
  /// админского заведения. Проброс до общего [BotService.createBot] (тот же
  /// путь, что и у self-service `myBots.create`) — второго механизма не
  /// заводим.
  _i3.Future<_i7.Bot> createBot({
    required String tenantExternalKey,
    String? productExternalKey,
    required String name,
    required String ownerEmail,
    required String capabilities,
    required bool discoverable,
  }) => caller.callServerEndpoint<_i7.Bot>(
    'botAdmin',
    'createBot',
    {
      'tenantExternalKey': tenantExternalKey,
      'productExternalKey': productExternalKey,
      'name': name,
      'ownerEmail': ownerEmail,
      'capabilities': capabilities,
      'discoverable': discoverable,
    },
  );

  /// **TASK36 (риск «Token leak»)**: выдать боту новый `accessToken`,
  /// отозвав все прежние. Личность бота, его членство в комнатах и история
  /// постов сохраняются — в отличие от прежнего совета «пересоздать бота».
  ///
  /// Возвращаемый [Bot] содержит новый `accessToken` — показать админу ОДИН
  /// раз. Программе бота нужно подставить новый токен: до этого момента её
  /// вызовы будут отвергнуты (старый токен отозван немедленно).
  _i3.Future<_i7.Bot> rotateBotToken({required int botId}) =>
      caller.callServerEndpoint<_i7.Bot>(
        'botAdmin',
        'rotateBotToken',
        {'botId': botId},
      );

  /// **TASK36 (аудит)**: журнал событий бота, свежие сверху. Кто завёл,
  /// кто ротировал credential, кто выключал, куда добавляли, во что бот
  /// ломился без grant-а (`capability_denied`).
  _i3.Future<List<_i8.BotAuditEvent>> listAuditEvents({
    required int botId,
    required int limit,
  }) => caller.callServerEndpoint<List<_i8.BotAuditEvent>>(
    'botAdmin',
    'listAuditEvents',
    {
      'botId': botId,
      'limit': limit,
    },
  );

  /// Список ботов tenant-а. `accessToken` наружу НЕ отдаётся (зануляется):
  /// credential виден один раз — в ответе [createBot] / [rotateBotToken].
  /// Скрытия в UI недостаточно — иначе токены всех ботов уезжали бы на
  /// клиента (wire/логи/память) при каждом открытии списка.
  _i3.Future<List<_i7.Bot>> listBots({required String tenantExternalKey}) =>
      caller.callServerEndpoint<List<_i7.Bot>>(
        'botAdmin',
        'listBots',
        {'tenantExternalKey': tenantExternalKey},
      );

  /// Включить / выключить бота (kill-switch). `enabled=false` →
  /// requireCapability бросает на любой gated-action.
  _i3.Future<_i7.Bot> setBotEnabled({
    required int botId,
    required bool enabled,
  }) => caller.callServerEndpoint<_i7.Bot>(
    'botAdmin',
    'setBotEnabled',
    {
      'botId': botId,
      'enabled': enabled,
    },
  );

  /// **issue #50**: все активные комнаты tenant-а для пикера «добавить
  /// бота в комнату». Обычный `rooms.list()` показывает комнаты самого
  /// админа — и целевой комнаты в пикере могло не быть, хотя
  /// [addBotToRoom] членства caller-а не требует. Anti-enumeration не
  /// аргумент: caller уже прошёл BOT_ADMIN_EMAILS-гейт и видит все боты
  /// tenant-а.
  _i3.Future<List<_i9.RoomSummary>> listAllRooms({required int limit}) =>
      caller.callServerEndpoint<List<_i9.RoomSummary>>(
        'botAdmin',
        'listAllRooms',
        {'limit': limit},
      );

  /// **issue #50, follow-up**: комнаты, где бот уже состоит, — пикер
  /// помечает их «уже добавлен» вместо молчаливого no-op при повторе.
  _i3.Future<List<int>> listBotRoomIds({required int botId}) =>
      caller.callServerEndpoint<List<int>>(
        'botAdmin',
        'listBotRoomIds',
        {'botId': botId},
      );

  /// Добавить бота в комнату: RoomMembership(participantKind=bot) +
  /// Matrix-join через bridge (reuse invite/add path). Идемпотентно —
  /// если бот уже member, no-op.
  _i3.Future<void> addBotToRoom({
    required int botId,
    required int roomId,
  }) => caller.callServerEndpoint<void>(
    'botAdmin',
    'addBotToRoom',
    {
      'botId': botId,
      'roomId': roomId,
    },
  );
}

/// **TASK59**: self-service бот-интеграция, принимающая сообщения.
///
/// Владелец/админ комнаты создаёт бота, который: (а) добавлен в его комнату,
/// (б) получает `message.created`/membership-события ЭТОЙ комнаты на свой
/// webhook-URL (room-scoped `WebhookSubscription` — приватность других комнат
/// tenant-а сохранена), (в) отвечает через `messenger/sendMessage` своим
/// bot-токеном. Гейт — owner/admin **этой** комнаты (self-service, НЕ
/// `BOT_ADMIN_EMAILS`), как у incoming-webhook. Provisioning из приложения
/// (v1); web-портал разработчика — следующий шаг.
/// {@category Endpoint}
class EndpointBotIntegration extends _i2.EndpointRef {
  EndpointBotIntegration(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'botIntegration';

  /// Создать бот-интеграцию: бот (`send_messages`) в комнате + room-scoped
  /// подписка на webhook-URL разработчика. Возвращает bot-токен + webhook-
  /// секрет + apiBase (показать один раз).
  _i3.Future<_i10.BotIntegrationCreated> createBotIntegration({
    required int roomId,
    required String name,
    required String webhookUrl,
    required String eventTypes,
  }) => caller.callServerEndpoint<_i10.BotIntegrationCreated>(
    'botIntegration',
    'createBotIntegration',
    {
      'roomId': roomId,
      'name': name,
      'webhookUrl': webhookUrl,
      'eventTypes': eventTypes,
    },
  );

  /// Список бот-интеграций комнаты (безопасный вид, без токенов/секретов).
  _i3.Future<List<_i11.BotIntegrationView>> listBotIntegrations({
    required int roomId,
  }) => caller.callServerEndpoint<List<_i11.BotIntegrationView>>(
    'botIntegration',
    'listBotIntegrations',
    {'roomId': roomId},
  );

  /// Ротация webhook-секрета (тот же бот). Старая подпись немедленно
  /// перестаёт совпадать. Возвращает новый секрет (показать один раз).
  _i3.Future<_i10.BotIntegrationCreated> rotateWebhookSecret({
    required int botId,
  }) => caller.callServerEndpoint<_i10.BotIntegrationCreated>(
    'botIntegration',
    'rotateWebhookSecret',
    {'botId': botId},
  );

  /// Вкл/выкл бот-интеграцию (бот + подписка вместе). `enabled=true` сбрасывает
  /// circuit-breaker подписки.
  _i3.Future<void> setEnabled({
    required int botId,
    required bool enabled,
  }) => caller.callServerEndpoint<void>(
    'botIntegration',
    'setEnabled',
    {
      'botId': botId,
      'enabled': enabled,
    },
  );

  /// Удалить бот-интеграцию (idempotent): удаляет подписку, гасит бота.
  _i3.Future<void> deleteBotIntegration({required int botId}) =>
      caller.callServerEndpoint<void>(
        'botIntegration',
        'deleteBotIntegration',
        {'botId': botId},
      );
}

/// **TASK78 п.1-3/5**: платформенное управление issued-token-режимом
/// tenant-ов — включение, генерация/ротация/отзыв serviceSecret, статус.
/// Это seam, который позже вызовет админ-экран «Интеграции»; сейчас
/// делает то же, что раньше требовало SQL + env + рестарт прода.
///
/// **Гейт** — email-allowlist env `PLATFORM_ADMIN_EMAILS` (те же правила,
/// что у BotAdminEndpoint, но отдельный список: управление tenant-ами
/// мощнее управления ботами). Env не задан → доступ запрещён всем
/// (безопасный дефолт: фича спит, пока платформа её не откроет). Unauthorized
/// → [MessengerNotAuthenticatedException] (anti-enumeration).
///
/// Секрет из [enableAndGenerate]/[rotateSecret] возвращается РОВНО ОДИН
/// РАЗ — в БД только sha256, повторно не показывается.
/// {@category Endpoint}
class EndpointConnectTenantAdmin extends _i2.EndpointRef {
  EndpointConnectTenantAdmin(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'connectTenantAdmin';

  /// **TASK78 п.3 (админ-UI)**: доступна ли caller-у платформенная
  /// админка. Нужен клиенту, чтобы не показывать пункт меню тому, кому
  /// все методы всё равно ответят отказом. НЕ гейтится и не бросает:
  /// авторизацию по-прежнему решает сервер на каждом методе, а сам факт
  /// «я не админ» ничего не раскрывает (образец — BotAdminEndpoint.isBotAdmin).
  _i3.Future<bool> isPlatformAdmin() => caller.callServerEndpoint<bool>(
    'connectTenantAdmin',
    'isPlatformAdmin',
    {},
  );

  /// **TASK78 п.3 (админ-UI)**: статусы issued-token-режима ВСЕХ
  /// tenant-ов (externalKey/имя/включён/секрет/grace, без секретов) —
  /// стартовый список админ-экрана. Гейт тот же, что у остальных методов.
  _i3.Future<List<_i12.ConnectTenantStatus>> listTenants() =>
      caller.callServerEndpoint<List<_i12.ConnectTenantStatus>>(
        'connectTenantAdmin',
        'listTenants',
        {},
      );

  /// Включить режим и выдать первый serviceSecret. Плейнтекст — в ответе,
  /// один раз. На уже включённом tenant-е это ротация (см. сервис).
  _i3.Future<String> enableAndGenerate({required String tenantExternalKey}) =>
      caller.callServerEndpoint<String>(
        'connectTenantAdmin',
        'enableAndGenerate',
        {'tenantExternalKey': tenantExternalKey},
      );

  /// Ротация без простоя: старый секрет живёт [graceSeconds] (по умолчанию
  /// 300). Возвращает новый плейнтекст.
  _i3.Future<String> rotateSecret({
    required String tenantExternalKey,
    int? graceSeconds,
  }) => caller.callServerEndpoint<String>(
    'connectTenantAdmin',
    'rotateSecret',
    {
      'tenantExternalKey': tenantExternalKey,
      'graceSeconds': graceSeconds,
    },
  );

  /// Отзыв режима (kill-switch). Со следующей аутентификации tenant не
  /// пускает; секрет очищается.
  _i3.Future<void> disable({required String tenantExternalKey}) =>
      caller.callServerEndpoint<void>(
        'connectTenantAdmin',
        'disable',
        {'tenantExternalKey': tenantExternalKey},
      );

  /// Статус режима (без секретов): включён / есть ли секрет / активен ли
  /// grace ротации.
  _i3.Future<_i12.ConnectTenantStatus> status({
    required String tenantExternalKey,
  }) => caller.callServerEndpoint<_i12.ConnectTenantStatus>(
    'connectTenantAdmin',
    'status',
    {'tenantExternalKey': tenantExternalKey},
  );

  /// Журнал операций с ключами tenant-а (свежие сверху), для аудита и
  /// диагностики. Секретов не содержит.
  _i3.Future<List<_i13.ConnectKeyAuditEvent>> listAuditEvents({
    required String tenantExternalKey,
    required int limit,
  }) => caller.callServerEndpoint<List<_i13.ConnectKeyAuditEvent>>(
    'connectTenantAdmin',
    'listAuditEvents',
    {
      'tenantExternalKey': tenantExternalKey,
      'limit': limit,
    },
  );
}

/// **S2S-endpoint варианта C** (DESIGN_CONNECT_ISSUED_TOKENS.md):
/// продукт-сервер, проверив СВОЕГО пользователя своим штатным способом
/// (сессия жива, isActive), делает один вызов [issueToken] и отдаёт
/// полученный токен своему клиенту. Клиент кладёт токен в
/// `MessengerAuthContext.accessToken` → [IssuedTokenAuthAdapter] гасит
/// его по таблице. Обратного connectVerify в продукт нет.
///
/// Авторизация вызова — per-tenant serviceSecret (sha256-хэш в
/// `Tenant.connectServiceSecretHash`, сравнение constant-time).
/// Секрет передаётся в ТЕЛЕ запроса (Serverpod RPC = POST), в query и в
/// логи не попадает.
/// {@category Endpoint}
class EndpointConnectToken extends _i2.EndpointRef {
  EndpointConnectToken(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'connectToken';

  /// Выдать одноразовый connect-токен (TTL 5 минут, см.
  /// [ConnectIssuedTokenService.tokenTtl]).
  ///
  /// Отказы: [InvalidTokenException] `reason=issue_denied` на ЛЮБУЮ
  /// проблему авторизации — «tenant не существует», «issued-token-режим
  /// выключен», «секрет неверен» снаружи неразличимы (реальная причина
  /// в server-логе). [ProductNotFoundException] — только после успешной
  /// проверки секрета. [RateLimitExceededException] — флуд выдачи либо
  /// серия неверных секретов.
  ///
  /// **[unauthenticatedClientCall]**: вызывающий — продукт-сервер, у
  /// него нет и не будет messenger-сессии; авторизация — serviceSecret.
  /// **TASK78 п.3**: опциональные [claims] (строка→строка, например
  /// `{'futbolista_organizer': 'true'}`) записываются в строку токена и
  /// при погашении возвращаются в `AuthAdapterResult.claims` — тем же
  /// контрактом, что у legacy-адаптеров варианта B. Продукт-сервер уже
  /// доказал себя serviceSecret-ом, поэтому claims-ам доверяем как и
  /// externalUserId/displayName.
  _i3.Future<_i14.ConnectIssuedTokenResult> issueToken({
    required String tenantExternalKey,
    required String productExternalKey,
    required String serviceSecret,
    required String externalUserId,
    required String displayName,
    Map<String, String>? claims,
  }) => caller.callServerEndpoint<_i14.ConnectIssuedTokenResult>(
    'connectToken',
    'issueToken',
    {
      'tenantExternalKey': tenantExternalKey,
      'productExternalKey': productExternalKey,
      'serviceSecret': serviceSecret,
      'externalUserId': externalUserId,
      'displayName': displayName,
      'claims': claims,
    },
    authenticated: false,
  );
}

/// **Email auth endpoint** — signup / signin / signout flow for tenants
/// using embedded email-password auth (alternative to customer SSO /
/// JWT bearer adapters of TASK24). Issues opaque session tokens stored
/// in [EmailSession]; tokens are then used as `MessengerAuthContext
/// .accessToken` in subsequent `MessengerEndpoint.session()` calls
/// (verified by `EmailAuthAdapter`).
///
/// **Anti-enumeration**: signIn returns identical exception reason
/// (`invalid_credentials`) for both "email not found" and "wrong
/// password" — prevents attacker enumerating valid emails. Server-side
/// log records the actual reason for ops.
///
/// **[unauthenticatedClientCall]** on all methods — каждый из них
/// первичная entry-point ДО получения session token. Без аннотации
/// `MutexRefresherClientAuthKeyProvider` на клиенте триггерит
/// `refreshAuthKey` перед каждым запросом → recursive deadlock
/// (см. TASK20 Chunk 5 cold-start fix).
/// {@category Endpoint}
class EndpointEmailAuth extends _i2.EndpointRef {
  EndpointEmailAuth(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailAuth';

  /// **Sign up** — создаёт нового [EmailAccount] и issuing-сессию.
  /// Возвращает [MessengerAuthContext] для последующего
  /// `MessengerEndpoint.session(ctx)` вызова.
  ///
  /// **Validations**:
  ///   * email matches `_emailRegex` (иначе `email_invalid_format`).
  ///   * password.length >= 8 (иначе `password_too_short`).
  ///   * username matches `^[a-z0-9_]{3,20}$` (иначе
  ///     `username_invalid_format`).
  ///   * email не существует в этом tenant-е (иначе `email_already_taken`).
  ///   * username не занят в этом tenant-е (иначе `username_taken`).
  ///
  /// **Вариант B (@username)** — username обязателен при регистрации,
  /// хранится lowercase, уникален per tenant (case-insensitive). DB
  /// unique-индекс — race-safe backstop (concurrent signUp с тем же
  /// handle → `username_taken`).
  ///
  /// **Email-гейт (issue #4)**: аккаунт создаётся с `verified: false` и
  /// сразу получает email-session token — он нужен клиенту для
  /// [verifyEmail]/[resendVerification]. Но «рабочей» сессии приложения
  /// у аккаунта НЕТ: обмен этого токена на messenger-сессию заблокирован
  /// в `EmailAuthAdapter` (reason='email_not_verified') до ввода кода из
  /// письма. Код отправляется здесь РОВНО ОДИН раз; повторная отправка —
  /// только явный [resendVerification] (rate-limited).
  _i3.Future<_i15.MessengerAuthContext> signUp({
    required String email,
    required String password,
    required String username,
    String? displayName,
    required String tenantExternalKey,
    String? productExternalKey,
    String? deviceId,
    _i16.DevicePlatform? platform,
    String? deviceName,
    String? appVersion,
  }) => caller.callServerEndpoint<_i15.MessengerAuthContext>(
    'emailAuth',
    'signUp',
    {
      'email': email,
      'password': password,
      'username': username,
      'displayName': displayName,
      'tenantExternalKey': tenantExternalKey,
      'productExternalKey': productExternalKey,
      'deviceId': deviceId,
      'platform': platform,
      'deviceName': deviceName,
      'appVersion': appVersion,
    },
    authenticated: false,
  );

  /// **Вариант B (@username)** — проверка доступности handle для live-
  /// валидации в UI регистрации (debounced на клиенте).
  ///
  /// Возвращает `true` если username:
  ///   * валиден по формату `^[a-z0-9_]{3,20}$` (после нормализации), И
  ///   * не занят в указанном tenant-е (case-insensitive).
  ///
  /// Невалидный формат → `false` (UI отдельно подсказывает формат через
  /// локальную проверку). Это не authoritative — финальная проверка
  /// уникальности происходит в [signUp] под защитой unique-индекса
  /// (между check и signUp возможна гонка).
  ///
  /// Rate-limit не вешаем: low-risk read-only lookup, без SMTP/enumeration-
  /// чувствительности (публичные handle-ы и так раскрываются в поиске).
  _i3.Future<bool> checkUsernameAvailable({
    required String username,
    required String tenantExternalKey,
  }) => caller.callServerEndpoint<bool>(
    'emailAuth',
    'checkUsernameAvailable',
    {
      'username': username,
      'tenantExternalKey': tenantExternalKey,
    },
    authenticated: false,
  );

  /// **Sign in** — verifies email+password, выдаёт новую [EmailSession].
  /// Returns [MessengerAuthContext] для последующего session-вызова.
  ///
  /// **Anti-enumeration**: invalid email OR wrong password оба бросают
  /// `EmailAuthException(reason: 'invalid_credentials')`. Atomic password
  /// verify time (PBKDF2 takes ~50ms regardless) убирает timing-side-
  /// channel на existence check.
  ///
  /// **Email-гейт (issue #4)**: для `verified: false` аккаунта signIn
  /// НАМЕРЕННО выдаёт email-session token (иначе клиенту нечем
  /// аутентифицировать [verifyEmail]/[resendVerification]), но этот токен
  /// НЕ обменивается на messenger-сессию — `EmailAuthAdapter` отвергает
  /// его с reason='email_not_verified' до подтверждения. Клиент после
  /// signIn читает [getAccountVerifiedStatus] и ведёт на экран кода.
  _i3.Future<_i15.MessengerAuthContext> signIn({
    required String email,
    required String password,
    required String tenantExternalKey,
    String? productExternalKey,
    String? deviceId,
    _i16.DevicePlatform? platform,
    String? deviceName,
    String? appVersion,
  }) => caller.callServerEndpoint<_i15.MessengerAuthContext>(
    'emailAuth',
    'signIn',
    {
      'email': email,
      'password': password,
      'tenantExternalKey': tenantExternalKey,
      'productExternalKey': productExternalKey,
      'deviceId': deviceId,
      'platform': platform,
      'deviceName': deviceName,
      'appVersion': appVersion,
    },
    authenticated: false,
  );

  /// **Sign out** — revokes a single session token.
  ///
  /// Idempotent: revoking an already-revoked / missing token is a no-op
  /// (no exception thrown). Client doesn't need to handle errors here —
  /// just clears its local store either way.
  _i3.Future<void> signOut({required String sessionToken}) =>
      caller.callServerEndpoint<void>(
        'emailAuth',
        'signOut',
        {'sessionToken': sessionToken},
        authenticated: false,
      );

  /// **Settings (Аккаунт)**: сменить пароль, зная текущий (в отличие от
  /// email-code reset). Авторизация — через [sessionToken] текущей
  /// сессии. Существующие сессии НЕ отзываются (для этого —
  /// [signOutAllOtherDevices]).
  _i3.Future<void> changePassword({
    required String sessionToken,
    required String currentPassword,
    required String newPassword,
  }) => caller.callServerEndpoint<void>(
    'emailAuth',
    'changePassword',
    {
      'sessionToken': sessionToken,
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    },
    authenticated: false,
  );

  /// **Settings (Аккаунт)**: «выйти со всех остальных устройств» —
  /// отзывает все EmailSession аккаунта КРОМЕ текущей. Другие устройства
  /// теряют свою email-сессию → не могут переоформить messenger-сессию
  /// (на следующем refresh выпадают). Текущее устройство остаётся в
  /// сессии. Возвращает число отозванных сессий.
  ///
  /// Messenger-токены здесь не трогаем: их revoke без точного «кроме
  /// текущего» рискует разлогинить текущее устройство; они истекут на
  /// ближайшем refresh-е, который у других устройств упадёт (email-сессия
  /// отозвана).
  _i3.Future<int> signOutAllOtherDevices({required String sessionToken}) =>
      caller.callServerEndpoint<int>(
        'emailAuth',
        'signOutAllOtherDevices',
        {'sessionToken': sessionToken},
        authenticated: false,
      );

  /// **Settings (Аккаунт) → «Устройства» (issue #23)**: список активных
  /// сессий аккаунта — устройство, платформа, версия, дата первого входа
  /// и последней активности. Аутентификация — по [sessionToken] текущей
  /// сессии (как остальные settings-методы).
  ///
  /// «Активная» = не отозвана (`revokedAt == null`) И не истекла
  /// (`expiresAt > now`). Отсортированы по последней активности (свежие
  /// сверху); текущее устройство помечено `isCurrent`.
  ///
  /// Возвращает `[]` если токен неизвестен / отозван / истёк (клиент и так
  /// в этот момент разлогинивается) — без исключения, чтобы экран не падал.
  ///
  /// **Безопасность**: наружу отдаётся только `EmailSession.id` (не
  /// секрет), а не `sessionToken` других устройств.
  _i3.Future<List<_i17.DeviceSessionInfo>> listMyDevices({
    required String sessionToken,
  }) => caller.callServerEndpoint<List<_i17.DeviceSessionInfo>>(
    'emailAuth',
    'listMyDevices',
    {'sessionToken': sessionToken},
    authenticated: false,
  );

  /// **Settings (Аккаунт) → «Устройства» (issue #23)**: точечный выход —
  /// отзывает ОДНУ сессию по её `id` (из [listMyDevices]). Аутентификация —
  /// по [sessionToken] вызывающего устройства.
  ///
  /// **Ownership-гейт**: отозвать можно только сессию ТОГО ЖЕ аккаунта
  /// (сверяем `emailAccountId` цели и вызывающего). Чужая / несуществующая
  /// цель → `false`, ничего не меняем (никакого раскрытия факта
  /// существования сессии другого аккаунта).
  ///
  /// Идемпотентно: повторный вызов на уже отозванной сессии → `false`.
  /// Отозвать можно и текущую сессию (id совпадает) — по сути logout;
  /// но UI для текущего устройства использует обычный выход (чистит
  /// локальное хранилище), а точечный revoke прячет.
  _i3.Future<bool> revokeDevice({
    required String sessionToken,
    required int targetSessionId,
  }) => caller.callServerEndpoint<bool>(
    'emailAuth',
    'revokeDevice',
    {
      'sessionToken': sessionToken,
      'targetSessionId': targetSessionId,
    },
    authenticated: false,
  );

  /// **Settings (Аккаунт) → «Устройства» (issue #23) — бэкфилл device-info**:
  /// заполняет `platform` / `deviceName` / `appVersion` на СУЩЕСТВУЮЩЕЙ
  /// сессии текущего устройства. Нужно для сессий, выпущенных до 1.0.58, —
  /// device-метаданные тогда слались только при signIn/signUp, поэтому в
  /// списке «Устройства» такие строки висели без платформы/имени/версии.
  /// Клиент вызывает этот метод один раз на старте (после init рантайма),
  /// передавая уже резолвнутые значения.
  ///
  /// **Семантика бэкфилла** (не даём кривому/устаревшему клиенту затереть
  /// то, что реально пришло при входе):
  ///   * `platform` / `deviceName` — пишем ТОЛЬКО если в строке они `null`;
  ///   * `appVersion` — освежаем всегда (версия приложения могла обновиться
  ///     с момента входа; точная метка полезна для триажа).
  ///
  /// Аутентификация — по [sessionToken] (как остальные settings-методы).
  /// Идемпотентно и best-effort: неизвестный / отозванный / истёкший токен →
  /// no-op → `false` (клиент в этот момент и так разлогинивается). `true`
  /// означает, что сессия найдена и активна (сама запись могла и не
  /// измениться, если бэкфиллить нечего).
  _i3.Future<bool> updateMyDeviceInfo({
    required String sessionToken,
    _i16.DevicePlatform? platform,
    String? deviceName,
    String? appVersion,
  }) => caller.callServerEndpoint<bool>(
    'emailAuth',
    'updateMyDeviceInfo',
    {
      'sessionToken': sessionToken,
      'platform': platform,
      'deviceName': deviceName,
      'appVersion': appVersion,
    },
    authenticated: false,
  );

  /// **Verify email** — exchange a 6-digit code for `account.verified = true`.
  /// On success returns the (possibly updated) [MessengerAuthContext] —
  /// идентичный тому, что выдан signUp / signIn, чтобы client не должен
  /// был ничего перевыпускать.
  ///
  /// **Auth** — caller passes their `sessionToken` (issued by signUp).
  /// Looks up account via session → matches code by `(accountId, code,
  /// unused, unexpired)`. Reasons на failure:
  ///   * `invalid_credentials` — session token bad.
  ///   * `code_invalid` — no match.
  ///   * `code_expired` — found but past expiresAt.
  ///   * `code_already_used` — usedAt is set.
  _i3.Future<_i15.MessengerAuthContext> verifyEmail({
    required String sessionToken,
    required String code,
    required String tenantExternalKey,
    String? productExternalKey,
    String? deviceId,
  }) => caller.callServerEndpoint<_i15.MessengerAuthContext>(
    'emailAuth',
    'verifyEmail',
    {
      'sessionToken': sessionToken,
      'code': code,
      'tenantExternalKey': tenantExternalKey,
      'productExternalKey': productExternalKey,
      'deviceId': deviceId,
    },
    authenticated: false,
  );

  /// **Request password reset** — generates a 6-digit code, stores with
  /// purpose='reset', sends via SMTP. Anti-enumeration: ALWAYS returns
  /// void / success, regardless of whether email exists. Attackers can't
  /// distinguish "email registered" from "email unknown" through this
  /// endpoint.
  ///
  /// Rate-limit: not implemented MVP (Phase2 — 1 send per 60s per email).
  /// SMTP failures don't propagate — logged for ops.
  _i3.Future<void> requestPasswordReset({
    required String email,
    required String tenantExternalKey,
  }) => caller.callServerEndpoint<void>(
    'emailAuth',
    'requestPasswordReset',
    {
      'email': email,
      'tenantExternalKey': tenantExternalKey,
    },
    authenticated: false,
  );

  /// **Confirm password reset** — exchange (email, code, newPassword)
  /// for a password update. On success the old password no longer
  /// works; the reset code is marked used; existing sessions remain
  /// valid (user not auto-logged-out). Phase2 may add `revokeAllSessions
  /// = true` toggle.
  ///
  /// Failure reasons (anti-enumeration unified for unknown-email):
  ///   * `invalid_credentials` — unknown email (same as "wrong code"
  ///     to prevent enumeration via timing).
  ///   * `code_invalid` / `code_expired` / `code_already_used` — known
  ///     email but bad code state.
  ///   * `password_too_short` — new password < 8 chars.
  _i3.Future<void> confirmPasswordReset({
    required String email,
    required String code,
    required String newPassword,
    required String tenantExternalKey,
  }) => caller.callServerEndpoint<void>(
    'emailAuth',
    'confirmPasswordReset',
    {
      'email': email,
      'code': code,
      'newPassword': newPassword,
      'tenantExternalKey': tenantExternalKey,
    },
    authenticated: false,
  );

  /// **Resend verification code** — generates a NEW code (previous codes
  /// remain in DB but expire naturally) and sends it. If account is
  /// already verified, throws [EmailAuthException(reason:
  /// 'already_verified')] — client receives this as a signal to refresh
  /// its local verified state (was potentially stale at `false`).
  ///
  /// **Phase2 rate-limit**: 1 send per 60s per account.
  _i3.Future<void> resendVerification({required String sessionToken}) =>
      caller.callServerEndpoint<void>(
        'emailAuth',
        'resendVerification',
        {'sessionToken': sessionToken},
        authenticated: false,
      );

  /// **Get account verified status** — lightweight read for client to
  /// refresh local state after signIn / hydrate. Bypasses code-send
  /// flow.
  ///
  /// Throws [EmailAuthException(reason: 'invalid_credentials')] if
  /// session token is bad. Returns `true` if account.verified.
  _i3.Future<bool> getAccountVerifiedStatus({required String sessionToken}) =>
      caller.callServerEndpoint<bool>(
        'emailAuth',
        'getAccountVerifiedStatus',
        {'sessionToken': sessionToken},
        authenticated: false,
      );
}

/// **TASK58**: in-app управление интеграциями комнаты (входящие webhook-и для
/// автопоста статусов).
///
/// Гейт — админ/owner **именно этой комнаты** (self-service, НЕ глобальный
/// `BOT_ADMIN_EMAILS`): владелец группы сам заводит и обслуживает автопосты.
/// Unauthorized → [MessengerNotAuthenticatedException] (anti-enumeration).
///
/// Создание webhook-а под капотом заводит бота-подпорку
/// ([BotService.createBot]) с capability `send_messages` и добавляет его в
/// комнату — постинг идёт через существующий messenger send-path. Ротация
/// токена бота НЕ пересоздаёт (имя отправителя/история постов сохраняются).
/// {@category Endpoint}
class EndpointIncomingWebhook extends _i2.EndpointRef {
  EndpointIncomingWebhook(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'incomingWebhook';

  /// Список интеграций комнаты (вкладка «Интеграции»).
  _i3.Future<List<_i18.IncomingWebhook>> listWebhooks({required int roomId}) =>
      caller.callServerEndpoint<List<_i18.IncomingWebhook>>(
        'incomingWebhook',
        'listWebhooks',
        {'roomId': roomId},
      );

  /// Создать автопост-webhook: заводит бота-подпорку, добавляет в комнату,
  /// генерит токен. Возвращает webhook + публичный токен (показать один раз).
  _i3.Future<_i19.IncomingWebhookCreated> createWebhook({
    required int roomId,
    required String name,
  }) => caller.callServerEndpoint<_i19.IncomingWebhookCreated>(
    'incomingWebhook',
    'createWebhook',
    {
      'roomId': roomId,
      'name': name,
    },
  );

  /// Ротация токена: новый публичный токен, тот же бот-подпорка (имя/история
  /// постов сохраняются). Старый токен немедленно перестаёт резолвиться.
  _i3.Future<_i19.IncomingWebhookCreated> rotateToken({required int id}) =>
      caller.callServerEndpoint<_i19.IncomingWebhookCreated>(
        'incomingWebhook',
        'rotateToken',
        {'id': id},
      );

  /// Вкл/выкл webhook без удаления.
  _i3.Future<_i18.IncomingWebhook> setEnabled({
    required int id,
    required bool enabled,
  }) => caller.callServerEndpoint<_i18.IncomingWebhook>(
    'incomingWebhook',
    'setEnabled',
    {
      'id': id,
      'enabled': enabled,
    },
  );

  /// Удалить webhook (idempotent). Гасит бота-подпорку (kill-switch).
  _i3.Future<void> deleteWebhook({required int id}) =>
      caller.callServerEndpoint<void>(
        'incomingWebhook',
        'deleteWebhook',
        {'id': id},
      );

  /// Тестовый пост — платформа сама шлёт пример статус-карточки в комнату
  /// (кнопка «Тестовый пост» в UI, проверка рендера без внешнего процесса).
  _i3.Future<void> testPost({required int id}) =>
      caller.callServerEndpoint<void>(
        'incomingWebhook',
        'testPost',
        {'id': id},
      );
}

/// Главный endpoint клиентского SDK. На TASK05 содержит только
/// [session]; в TASK13+ обрастает room/message/push методами.
/// {@category Endpoint}
class EndpointMessenger extends _i2.EndpointRef {
  EndpointMessenger(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'messenger';

  /// Создаёт серверную сессию по `MessengerAuthContext`.
  ///
  /// Шаги (см. TASK05):
  ///   1. Найти tenant по externalKey.
  ///   2. Опционально найти product.
  ///   3. Получить адаптер из [AuthAdapterRegistry].
  ///   4. Вычислить identityProviderKey.
  ///   5. Вызвать adapter.verify().
  ///   6. Получить или создать MessengerUser
  ///      (TASK06 заменит на `IdentityMappingService.getOrCreate`).
  ///   7. Сгенерировать sessionToken и вернуть [MessengerSession].
  ///
  /// Negative-сценарии — Serverpod-сериализуемые типизированные
  /// исключения ([TenantNotFoundException], [ProductNotFoundException],
  /// [AdapterNotConfiguredException], [InvalidTokenException]). Эти
  /// классы codegen-ятся и в server-, и в client-пакете, так что SDK
  /// разбирает их по типу, а не по строке `message`.
  ///
  /// **[unauthenticatedClientCall]**: первый вход — ещё нет
  /// `sessionToken`-а. Без этой аннотации `MutexRefresherClientAuthKeyProvider`
  /// на клиенте триггерит `refreshAuthKey` перед каждым запросом, что
  /// рекурсивно зовёт сюда же → deadlock. См. doc у
  /// `RefresherClientAuthKeyProvider` в `serverpod_client`.
  _i3.Future<_i20.MessengerSession> session(_i15.MessengerAuthContext ctx) =>
      caller.callServerEndpoint<_i20.MessengerSession>(
        'messenger',
        'session',
        {'ctx': ctx},
        authenticated: false,
      );

  /// Refresh сессии: принимает тот же `MessengerAuthContext`, что был
  /// отдан в `session()`, проверяет его адаптером, выдаёт **новый**
  /// `sessionToken` для того же `messengerUserId`. [previousToken] —
  /// токен, который клиент этим вызовом заменяет; он и отзывается.
  ///
  /// Семантика: повторный вход того же external user-а под идентичным
  /// контекстом → тот же `messengerUserId`. Это критично для invariant-а
  /// «один external user = одна messenger-личность» (см. TASK04, §6 ТЗ).
  ///
  /// **Почему отзываем ИМЕННО [previousToken], а не все токены юзера.**
  /// Раньше refresh отзывал все неотозванные токены `messengerUserId` —
  /// исходя из «один пользователь = одна сессия». Для мультидевайса это
  /// смертельно: телефон рефрешится → убивает токен десктопа → десктоп
  /// ловит 401 → рефрешится → убивает телефон → бесконечная петля. Замер
  /// прода 2026-07-16: у одного юзера **106 токенов за час**, медианное
  /// время жизни токена **30 секунд** вместо 24 часов; 95% всех RPC падали
  /// с `MessengerNotAuthenticatedException`. Побочно это ломало звонки
  /// (`getTurnCredentials` не проходил → клиент молча уходил на STUN-only
  /// без relay) и сохранение визитки.
  ///
  /// [previousToken] == null → **не отзываем ничего**. Это намеренно:
  /// уже выложенные клиенты параметр не шлют, и для них петля прекращается
  /// сразу после деплоя сервера, без обновления приложений. Старый токен у
  /// них просто доживёт до `expiresAt`.
  ///
  /// Гард `messengerUserId` обязателен: метод [unauthenticatedClientCall],
  /// поэтому без него любой мог бы отозвать ЧУЖОЙ токен, передав его сюда.
  /// С гардом отзыв возможен только в пределах юзера, которым вызывающий
  /// только что аутентифицировался.
  ///
  /// **[unauthenticatedClientCall]**: аналогично [session], нужно чтобы
  /// клиентский mutex-refresher не зацикливал refresh → authHeader → refresh.
  _i3.Future<_i20.MessengerSession> refresh(
    _i15.MessengerAuthContext ctx, {
    String? previousToken,
  }) => caller.callServerEndpoint<_i20.MessengerSession>(
    'messenger',
    'refresh',
    {
      'ctx': ctx,
      'previousToken': previousToken,
    },
    authenticated: false,
  );

  /// Отозвать sessionToken (logout). Идемпотентно — повторный вызов с уже
  /// отозванным токеном это no-op.
  ///
  /// `sessionToken` принимаем параметром (не из authenticated session),
  /// чтобы revoke работал даже когда серверная сессия уже не доверяет
  /// токену по какой-то причине (истёк / уже однажды revoke-нут / просто
  /// «dead session» на стороне SDK после crash-а).
  ///
  /// **Design choice (см. ревью c9c7856 #3):** revoke намеренно НЕ
  /// проверяет, что caller владелец токена. Угадать 32-байтный
  /// random-токен невозможно (2^256), а ограничение «только authenticated
  /// owner может revoke» сделало бы dead-session cleanup невозможным.
  /// Если токен утёк через лог — это отдельная проблема (TASK24
  /// hashing-at-rest); известный утёкший токен владелец отзывает этим же
  /// `revoke`, а при утечке неизвестного объёма («не знаю, что утекло»)
  /// — [revokeAllTokens], который убивает ВСЕ живые токены юзера разом.
  /// (`refresh` с 2026-07-16 отзывает ровно `previousToken` и для
  /// leak-mitigation больше не годится.)
  _i3.Future<void> revoke({required String sessionToken}) =>
      caller.callServerEndpoint<void>(
        'messenger',
        'revoke',
        {'sessionToken': sessionToken},
      );

  /// Incident response «токен утёк, убить всё»: отзывает ВСЕ неотозванные
  /// [MessengerSessionToken] текущего аутентифицированного юзера — на всех
  /// устройствах, ВКЛЮЧАЯ токен, которым сделан этот вызов. После вызова
  /// клиент обязан пройти `session()` заново; это осознанно.
  ///
  /// Появился взамен старой семантики `refresh` («отозвать все токены
  /// юзера»), которую 3c9d78e сузил до одного `previousToken` ради
  /// мультидевайса — иначе у владельца не осталось бы способа
  /// компенсировать утечку одним вызовом.
  ///
  /// В отличие от [revoke], метод НЕ [unauthenticatedClientCall]:
  /// `messengerUserId` берётся из аутентифицированной сессии
  /// ([requireMessengerUserId]), параметром не принимается — иначе любой
  /// мог бы разлогинить чужого юзера, зная только его id.
  _i3.Future<void> revokeAllTokens() => caller.callServerEndpoint<void>(
    'messenger',
    'revokeAllTokens',
    {},
  );

  /// Отправить сообщение в комнату от лица текущего authenticated юзера.
  ///
  /// `attachment` (TASK19) — опциональная media-ссылка из предшествующего
  /// `uploadAttachment`. Если задана, server переопределяет `msgtype`
  /// на `m.image`/`m.video`/`m.file` per `attachment.mimeType` и кладёт
  /// `info` block в Matrix content (mxc url, dimensions, size).
  _i3.Future<_i21.MessengerMessage> sendMessage({
    required int roomId,
    required String body,
    required String msgType,
    String? clientTxnId,
    String? threadId,
    String? replyToMatrixEventId,
    _i22.AttachmentRef? attachment,
    List<int>? mentionedMessengerUserIds,
    String? albumId,
    String? forwardedFromName,
    int? forwardedFromMessengerUserId,
    int? forwardedFromRoomId,
    String? forwardedFromEventId,
  }) => caller.callServerEndpoint<_i21.MessengerMessage>(
    'messenger',
    'sendMessage',
    {
      'roomId': roomId,
      'body': body,
      'msgType': msgType,
      'clientTxnId': clientTxnId,
      'threadId': threadId,
      'replyToMatrixEventId': replyToMatrixEventId,
      'attachment': attachment,
      'mentionedMessengerUserIds': mentionedMessengerUserIds,
      'albumId': albumId,
      'forwardedFromName': forwardedFromName,
      'forwardedFromMessengerUserId': forwardedFromMessengerUserId,
      'forwardedFromRoomId': forwardedFromRoomId,
      'forwardedFromEventId': forwardedFromEventId,
    },
  );

  /// **TASK38**: создать задачу во внешнем таск-трекере из сообщения.
  /// Caller должен быть членом комнаты. Сервер резолвит per-tenant
  /// integration-конфиг, POST-ит сообщение (HMAC-подписано) на integration
  /// URL, пишет [TaskLink] и best-effort постит confirmation через
  /// `@nsg-system`. Нет enabled-конфига →
  /// [TaskIntegrationNotConfiguredException].
  _i3.Future<_i23.TaskLink> createTaskFromMessage({
    required int roomId,
    required String matrixEventId,
    required String body,
  }) => caller.callServerEndpoint<_i23.TaskLink>(
    'messenger',
    'createTaskFromMessage',
    {
      'roomId': roomId,
      'matrixEventId': matrixEventId,
      'body': body,
    },
  );

  /// **TASK38 UI-gating**: доступна ли task-интеграция для комнаты —
  /// показывать ли клиенту пункт «Создать задачу». Caller-член комнаты;
  /// `false` если нет enabled-конфига (а не исключение — это hot-path UI).
  _i3.Future<bool> isTaskIntegrationAvailable({required int roomId}) =>
      caller.callServerEndpoint<bool>(
        'messenger',
        'isTaskIntegrationAvailable',
        {'roomId': roomId},
      );

  /// **TASK37**: edit own message — Matrix `m.replace`. Authorization
  /// own-only (Q2): server compares `event.sender ==
  /// caller.matrixUserId`. Anti-enumeration через
  /// [MessageNotEditableException] (single shape для not-found AND
  /// not-owned).
  ///
  /// `newBody` empty/whitespace → `ArgumentError`. Edit deleted →
  /// [MessageDeletedException]. Msgtype preserved (Q2 invariant —
  /// `m.image` остаётся `m.image`, edit меняет только body/caption).
  _i3.Future<_i21.MessengerMessage> editMessage({
    required int roomId,
    required String matrixEventId,
    required String newBody,
    List<int>? mentionedMessengerUserIds,
  }) => caller.callServerEndpoint<_i21.MessengerMessage>(
    'messenger',
    'editMessage',
    {
      'roomId': roomId,
      'matrixEventId': matrixEventId,
      'newBody': newBody,
      'mentionedMessengerUserIds': mentionedMessengerUserIds,
    },
  );

  /// **TASK37**: delete own message — Matrix `m.room.redaction`.
  /// Idempotent: redact already-redacted → success. Authorization
  /// own-only (Q2). Cross-user delete (admin/moderation) — TASK29.
  _i3.Future<void> deleteMessage({
    required int roomId,
    required String matrixEventId,
  }) => caller.callServerEndpoint<void>(
    'messenger',
    'deleteMessage',
    {
      'roomId': roomId,
      'matrixEventId': matrixEventId,
    },
  );

  /// **B9 typing indicator**: уведомить других участников комнаты что
  /// текущий пользователь печатает (`typing=true`) или перестал
  /// (`typing=false`).
  ///
  /// Matrix `m.typing` EDU авто-гасится через 30s если повторный
  /// `typing=true` не пришёл, поэтому клиент шлёт:
  ///   * первый keystroke → `sendTyping(true)`;
  ///   * каждые ~10-20s пока пользователь печатает (renew);
  ///   * после ~5s без новых keystrokes ИЛИ после `sendMessage` →
  ///     `sendTyping(false)` (explicit cancel, не ждём timeout).
  ///
  /// Errors не propagate — typing best-effort.
  _i3.Future<void> sendTyping({
    required int roomId,
    required bool typing,
  }) => caller.callServerEndpoint<void>(
    'messenger',
    'sendTyping',
    {
      'roomId': roomId,
      'typing': typing,
    },
  );

  /// **Emoji reactions**: поставить реакцию `key` (emoji) на сообщение
  /// `targetEventId`. Возвращает matrixEventId самого `m.reaction`
  /// event-а — SDK хранит его для toggle-off (`removeReaction`).
  _i3.Future<String> sendReaction({
    required int roomId,
    required String targetEventId,
    required String key,
  }) => caller.callServerEndpoint<String>(
    'messenger',
    'sendReaction',
    {
      'roomId': roomId,
      'targetEventId': targetEventId,
      'key': key,
    },
  );

  /// **Emoji reactions**: снять свою реакцию через redaction
  /// reaction-event-а `reactionEventId`. Idempotent.
  _i3.Future<void> removeReaction({
    required int roomId,
    required String reactionEventId,
  }) => caller.callServerEndpoint<void>(
    'messenger',
    'removeReaction',
    {
      'roomId': roomId,
      'reactionEventId': reactionEventId,
    },
  );

  /// **Issue #35**: закрепить сообщение [matrixEventId] в комнате. Idempotent.
  /// Возвращает новый полный список закреплённых matrixEventId (oldest-first)
  /// — SDK сразу обновляет плашку без отдельного `listPinnedMessages`.
  ///
  /// Права ([PinService] / [PinPolicy]): в direct-чате — любой участник; в
  /// группах/командах — только admin/owner. Иначе [InsufficientPowerException].
  /// Не-участник / несуществующая комната — [RoomUnavailableException].
  ///
  /// Realtime: после успешного PUT Matrix `/sync` доставит
  /// `m.room.pinned_events` остальным участникам —
  /// `MatrixSyncDispatcher._processPinnedEvents` эмитит
  /// `pinnedMessagesChanged` в их `userEventStream`.
  _i3.Future<List<String>> pinMessage({
    required int roomId,
    required String matrixEventId,
  }) => caller.callServerEndpoint<List<String>>(
    'messenger',
    'pinMessage',
    {
      'roomId': roomId,
      'matrixEventId': matrixEventId,
    },
  );

  /// **Issue #35**: снять закрепление сообщения [matrixEventId]. Idempotent.
  /// Возвращает новый список закреплённых id. Права — те же, что у [pinMessage].
  _i3.Future<List<String>> unpinMessage({
    required int roomId,
    required String matrixEventId,
  }) => caller.callServerEndpoint<List<String>>(
    'messenger',
    'unpinMessage',
    {
      'roomId': roomId,
      'matrixEventId': matrixEventId,
    },
  );

  /// **Issue #35**: список закреплённых сообщений комнаты как
  /// [MessengerMessage]-DTO (для плашки закреплённых). Доступно любому
  /// участнику. Порядок — oldest-first (как в `m.room.pinned_events`).
  /// Пустой список — если ничего не закреплено.
  _i3.Future<List<_i21.MessengerMessage>> listPinnedMessages({
    required int roomId,
  }) => caller.callServerEndpoint<List<_i21.MessengerMessage>>(
    'messenger',
    'listPinnedMessages',
    {'roomId': roomId},
  );

  /// **TASK46**: отправить `m.call.*` событие сигналинга в direct-комнату
  /// от лица текущего юзера (server-proxy — SDK не имеет Matrix-токена).
  ///
  /// Server собирает Matrix VoIP content (MSC2746) по [eventType]:
  ///   * `invite`       → `m.call.invite`       (SDP offer в [sdp] + lifetime)
  ///   * `answer`       → `m.call.answer`       (SDP answer в [sdp])
  ///   * `candidates`   → `m.call.candidates`   (trickle ICE в [candidates])
  ///   * `hangup`       → `m.call.hangup`       (причина в [hangupReason])
  ///   * `selectAnswer` → `m.call.select_answer`([selectedPartyId], glare)
  ///   * `reject`       → `m.call.reject`
  ///   * `negotiate`    → `m.call.negotiate`    (ICE restart / renegotiation:
  ///                       [sdp] + [sdpType]=`offer`/`answer` в `description`)
  ///
  /// [callId] группирует все события одного звонка (UUID от caller-а),
  /// [partyId] — идентификатор устройства-участника (multi-device).
  ///
  /// Второе устройство получает событие через `userEventStream`
  /// (dispatcher мапит Matrix `m.call.*` → `MessengerEvent(call*)`).
  ///
  /// Валидация: caller — участник direct 1:1 комнаты (иначе StateError /
  /// ArgumentError). Rate-limit: 30 call-событий/10с на юзера
  /// ([callEventRateLimiter]) — trickle ICE может быть частым, но не
  /// безлимитным. Превышение → [RateLimitExceededException].
  _i3.Future<void> sendCallEvent({
    required int roomId,
    required _i24.CallEventType eventType,
    required String callId,
    required String partyId,
    String? sdp,
    List<_i25.CallIceCandidate>? candidates,
    String? hangupReason,
    String? selectedPartyId,
    String? sdpType,
  }) => caller.callServerEndpoint<void>(
    'messenger',
    'sendCallEvent',
    {
      'roomId': roomId,
      'eventType': eventType,
      'callId': callId,
      'partyId': partyId,
      'sdp': sdp,
      'candidates': candidates,
      'hangupReason': hangupReason,
      'selectedPartyId': selectedPartyId,
      'sdpType': sdpType,
    },
  );

  /// **TASK46**: выдать эфемерные TURN/STUN креды для WebRTC ICE (см.
  /// TASK46 §2.1). Клиент кладёт результат в `RTCConfiguration.iceServers`
  /// перед созданием `RTCPeerConnection`, обновляет перед истечением
  /// `ttlSeconds`.
  ///
  /// Схема coturn `use-auth-secret`: username=`<expiry>:<userId>`,
  /// credential=base64(HMAC-SHA1(secret, username)). Требует авторизации.
  ///
  /// Если TURN не сконфигурирован (нет env `TURN_URLS` /
  /// `turnStaticAuthSecret`) — возвращает `urls:[]` (фича выключена, клиент
  /// использует только публичные STUN). Не бросает — feature-toggle, не
  /// ошибка конфигурации.
  _i3.Future<_i26.TurnCredentials> getTurnCredentials() =>
      caller.callServerEndpoint<_i26.TurnCredentials>(
        'messenger',
        'getTurnCredentials',
        {},
      );

  /// **TASK46 (звонки в фоне)**: дотянуть pending `callInvite` по [callId].
  ///
  /// Нужно клиенту, разбуженному push-ом на входящий звонок из УБИТОГО
  /// состояния: сервер уже consumed live `m.call.invite` (чтобы послать
  /// push) до того, как клиент успел подписаться на realtime-стрим, —
  /// поэтому invite (с SDP-offer) надо дотянуть отдельно. Клиент кормит
  /// результат в `CallController.ingestFetchedInvite` → звонок звонит и
  /// может быть принят.
  ///
  /// Источник — global-кэш `pendingcall:<me>:<callId>` (кладёт
  /// `MatrixSyncDispatcher._processCallEvent` на callInvite, TTL ~65с =
  /// invite-lifetime). Возвращает `null`, если звонок завершён/истёк.
  /// Скоуп по текущему пользователю — чужой SDP не отдаём.
  _i3.Future<_i27.MessengerEvent?> fetchCallInvite({required String callId}) =>
      caller.callServerEndpoint<_i27.MessengerEvent?>(
        'messenger',
        'fetchCallInvite',
        {'callId': callId},
      );

  /// **TASK46 (история звонков)**: список звонков текущего пользователя
  /// (он мог быть и звонящим, и принимающим), новейшие первыми. Клиент
  /// рисует их во вкладке «Звонки»: направление/пропущенный выводит
  /// per-viewer (viewer==caller → исходящий), имя собеседника резолвит
  /// по `roomId`. [limit] капается в диапазон 1..200.
  _i3.Future<List<_i28.CallHistoryEntry>> listCallHistory({
    required int limit,
  }) => caller.callServerEndpoint<List<_i28.CallHistoryEntry>>(
    'messenger',
    'listCallHistory',
    {'limit': limit},
  );

  /// **TASK51**: войти в конференцию комнаты (создав её, если активной
  /// нет). Возвращает актуальный состав — SDK строит pairwise 1:1-сессии
  /// (TASK46-сигналинг, свой callId на пару) с каждым участником из
  /// `members`; сам сигналинг остаётся `sendCallEvent` как есть.
  ///
  /// [partyId] — тот же per-device uuid, что в pairwise-сигналинге:
  /// по паре (messengerUserId, partyId) остальные адресуют сессии.
  ///
  /// **Контракт keepalive**: повторный join идемпотентен и продлевает
  /// `lastSeenAt`; SDK ОБЯЗАН перевызывать joinConference не реже, чем
  /// раз в половину TTL (default TTL 90с → интервал 30с рекомендован) —
  /// иначе участник будет зачищен как «призрак» (краш-семантика).
  ///
  /// Отказы: [RoomUnavailableException] (нет комнаты / не участник —
  /// единый вид, anti-enumeration), [ConferenceFullException] (серверный
  /// лимит mesh, §3A.5), [RateLimitExceededException].
  _i3.Future<_i29.ConferenceState> joinConference({
    required int roomId,
    required String partyId,
  }) => caller.callServerEndpoint<_i29.ConferenceState>(
    'messenger',
    'joinConference',
    {
      'roomId': roomId,
      'partyId': partyId,
    },
  );

  /// **TASK51**: штатный выход из конференции комнаты. Идемпотентно
  /// (не в конференции / конференции нет → no-op). Последний вышедший
  /// убивает конференцию. Остальным доезжает `conferenceUpdated` — они
  /// сносят pairwise-сессии с ушедшим (плюс он сам шлёт им hangup по
  /// парам, это дублирующая страховка).
  _i3.Future<void> leaveConference({required int roomId}) =>
      caller.callServerEndpoint<void>(
        'messenger',
        'leaveConference',
        {'roomId': roomId},
      );

  /// **TASK51**: актуальный состав активной конференции комнаты или
  /// `null`, если её нет. Поздний участник (и просто открывший комнату)
  /// получает состав одним запросом — для бейджа «идёт конференция,
  /// N человек» и решения войти. [RoomUnavailableException] — не участник.
  _i3.Future<_i29.ConferenceState?> getConference({required int roomId}) =>
      caller.callServerEndpoint<_i29.ConferenceState?>(
        'messenger',
        'getConference',
        {'roomId': roomId},
      );

  /// **Reactions history (phase 2)**: для списка message `eventIds`
  /// возвращает существующие реакции как `reactionChanged`-add
  /// `MessengerEvent`-ы (тот же shape что realtime). SDK скармливает их
  /// в aggregation-путь после `listMessages`, чтобы реакции были видны
  /// сразу при открытии чата. Пустой `eventIds` → пустой list.
  _i3.Future<List<_i27.MessengerEvent>> listReactions({
    required int roomId,
    required List<String> eventIds,
  }) => caller.callServerEndpoint<List<_i27.MessengerEvent>>(
    'messenger',
    'listReactions',
    {
      'roomId': roomId,
      'eventIds': eventIds,
    },
  );

  /// **Persistent read-receipts seed (B22)**: при открытии чата
  /// возвращает persisted read-pointer-ы всех участников комнаты (КРОМЕ
  /// self) как `readReceiptUpdated`-`MessengerEvent`-ы — тот же shape что
  /// realtime `m.receipt`. SDK скармливает их в `_applyReadReceipt`-путь,
  /// чтобы ✓✓ были видны сразу (раньше терялись до первого realtime
  /// receipt-а, т.к. `_peerLastReadAt` volatile). Локальный SELECT, БЕЗ
  /// обращения к Matrix.
  _i3.Future<List<_i27.MessengerEvent>> listReadReceipts({
    required int roomId,
  }) => caller.callServerEndpoint<List<_i27.MessengerEvent>>(
    'messenger',
    'listReadReceipts',
    {'roomId': roomId},
  );

  /// **TASK29**: kick — caller-admin удаляет target из комнаты. Target
  /// **может re-join** (через invite). Authorization: caller `role >=
  /// admin` (PL >= 50).
  ///
  /// Throws:
  ///   * [RoomUnavailableException] — room не существует / caller не
  ///     member / target не member / cross-tenant (anti-enumeration).
  ///   * [InsufficientPowerException] — caller-`role == 'member'`.
  _i3.Future<void> kickUser({
    required int roomId,
    required int targetMessengerUserId,
    String? reason,
  }) => caller.callServerEndpoint<void>(
    'messenger',
    'kickUser',
    {
      'roomId': roomId,
      'targetMessengerUserId': targetMessengerUserId,
      'reason': reason,
    },
  );

  /// **B15 rename room**: caller-admin переименовывает group-комнату.
  /// Direct chats — `ArgumentError` (name у direct = peer displayName,
  /// rename семантически странный). Validations:
  /// * trim non-empty;
  /// * length ≤ 100 chars;
  /// * caller PL ≥ 50 (admin).
  ///
  /// Realtime — другие участники получат `roomStateChanged{field='name'}`
  /// через `userEventStream`; local Room.name UPDATE-нется автоматически
  /// через sync flow.
  _i3.Future<void> renameRoom({
    required int roomId,
    required String newName,
  }) => caller.callServerEndpoint<void>(
    'messenger',
    'renameRoom',
    {
      'roomId': roomId,
      'newName': newName,
    },
  );

  /// **Atomic dissolveRoom**: owner распускает group-комнату — сервер
  /// kick-ает всех остальных участников и затем leave-ит сам, в одном
  /// RPC. Заменяет клиентский loop `kickUser`/`leaveRoom` из
  /// `GroupSettingsScreen._dissolveGroup` — устойчиво к network blip
  /// посередине: при partial failure возвращается
  /// `RoomDissolvePartialException(kicked, total, cause)`, и UI может
  /// retry тем же endpoint-ом (idempotent).
  ///
  /// Authorization: caller-`role == 'owner'`. `direct` chats отклоняются
  /// `ArgumentError` (для них семантически нужен `leaveRoom`).
  _i3.Future<void> dissolveRoom({required int roomId}) =>
      caller.callServerEndpoint<void>(
        'messenger',
        'dissolveRoom',
        {'roomId': roomId},
      );

  /// **TASK29**: ban — caller-admin удаляет target И блокирует rejoin.
  /// Target не может invite-ся обратно до `unbanUser`. Authorization
  /// та же, что у [kickUser].
  _i3.Future<void> banUser({
    required int roomId,
    required int targetMessengerUserId,
    String? reason,
  }) => caller.callServerEndpoint<void>(
    'messenger',
    'banUser',
    {
      'roomId': roomId,
      'targetMessengerUserId': targetMessengerUserId,
      'reason': reason,
    },
  );

  /// **TASK29**: unban — снимает ban. Target снова может invite-ся.
  /// `RoomMembership` НЕ восстанавливается автоматически — для re-add
  /// нужен отдельный invite вызов.
  _i3.Future<void> unbanUser({
    required int roomId,
    required int targetMessengerUserId,
  }) => caller.callServerEndpoint<void>(
    'messenger',
    'unbanUser',
    {
      'roomId': roomId,
      'targetMessengerUserId': targetMessengerUserId,
    },
  );

  /// **TASK29**: setRoomMemberRole — promote / demote target's role.
  /// Authorization: caller-`role == 'owner'` (PL >= 100).
  ///
  /// Last-owner demote rejected с
  /// [LastOwnerCannotDemoteException]. Mapping: member→PL=0, admin→50,
  /// owner→100. После update server обновляет local
  /// `RoomMembership.{role, powerLevel}` И PUT-ит обновлённый
  /// `m.room.power_levels` в Matrix; subsequent /sync echo для всех
  /// participants синхронизирует их local state через
  /// [MatrixSyncDispatcher._processPowerLevels].
  _i3.Future<void> setRoomMemberRole({
    required int roomId,
    required int targetMessengerUserId,
    required _i30.RoomMemberRole newRole,
  }) => caller.callServerEndpoint<void>(
    'messenger',
    'setRoomMemberRole',
    {
      'roomId': roomId,
      'targetMessengerUserId': targetMessengerUserId,
      'newRole': newRole,
    },
  );

  /// **TASK29 Chunk 2**: список banned users в комнате — для admin
  /// `BannedUsersScreen` UI. Caller `role >= admin`. Federation banned
  /// users отфильтрованы (DTO requires non-null messengerUserId).
  _i3.Future<List<_i31.RoomParticipant>> listBannedUsers({
    required int roomId,
  }) => caller.callServerEndpoint<List<_i31.RoomParticipant>>(
    'messenger',
    'listBannedUsers',
    {'roomId': roomId},
  );

  /// **TASK19 Chunk 1**: загрузить media в Matrix через uploader's matrix
  /// token. Server-proxy mandatory (TASK07 invariant). Validates MIME
  /// whitelist + extension blacklist + size cap (50MB image/file,
  /// 100MB video, 200MB hard cap). Server-side dimension probing для
  /// image (image package, header-only fast).
  ///
  /// Возвращает [AttachmentRef] для последующего `sendMessage(attachment:)`.
  _i3.Future<_i22.AttachmentRef> uploadAttachment({
    required _i32.ByteData bytes,
    required String mimeType,
    required String originalFilename,
  }) => caller.callServerEndpoint<_i22.AttachmentRef>(
    'messenger',
    'uploadAttachment',
    {
      'bytes': bytes,
      'mimeType': mimeType,
      'originalFilename': originalFilename,
    },
  );

  /// **B16-extension: загрузка user-аватара**.
  ///
  /// Принимает image bytes (recommended ≤ 2MB, server-side cap внутри
  /// attachment-service) + MIME. Под капотом:
  ///   1. Validate MIME — image-only (image/png, image/jpeg, image/webp,
  ///      image/gif). HEIC/HEIF тоже ОК (Synapse сохранит без probe).
  ///   2. Upload через `attachmentService.upload(...)` — то же что для
  ///      обычных attachment-ов, но `originalFilename = "avatar.<ext>"`.
  ///   3. Save mxcUrl в `MessengerUser.avatarUrl`.
  ///   4. Best-effort `matrixBridgeService.setAvatar(...)` — обновляем
  ///      Matrix profile, чтобы и другие matrix-клиенты увидели аватар.
  ///      Ошибка bridge'а НЕ failит endpoint — DB уже сохранена, SDK
  ///      покажет новый аватар, matrix profile подтянется позже
  ///      retry-логикой или вручную.
  ///
  /// Возвращает обновлённый `MessengerUser.avatarUrl` (= mxcUrl).
  _i3.Future<String> uploadUserAvatar({
    required _i32.ByteData bytes,
    required String mimeType,
  }) => caller.callServerEndpoint<String>(
    'messenger',
    'uploadUserAvatar',
    {
      'bytes': bytes,
      'mimeType': mimeType,
    },
  );

  /// **B16-ext (group avatar)**: загрузка/смена аватара group/team/
  /// productRoom-комнаты. Принимает image bytes + MIME. Под капотом:
  ///   1. Validate MIME (image/*).
  ///   2. Upload через `attachmentService.upload(...)` (тот же flow что
  ///      для user-avatar и attachment-ов).
  ///   3. Делегирует в `roomAdminService.setRoomAvatar` — admin PL-guard,
  ///      `PUT /state/m.room.avatar`, UPDATE `Room.avatarUrl`.
  ///
  /// Direct chats reject-аются: для direct аватар = peer's
  /// `MessengerUser.avatarUrl` (нет per-room override).
  ///
  /// Возвращает mxcUrl.
  _i3.Future<String> setRoomAvatar({
    required int roomId,
    required _i32.ByteData bytes,
    required String mimeType,
  }) => caller.callServerEndpoint<String>(
    'messenger',
    'setRoomAvatar',
    {
      'roomId': roomId,
      'bytes': bytes,
      'mimeType': mimeType,
    },
  );

  /// **TASK19 Chunk 1**: скачать media через caller's matrix token
  /// (Matrix Authenticated Media — Synapse 1.100+ обязателен).
  /// Caller должен быть member хотя бы одной комнаты, где media
  /// post-нута; Matrix verify-ит автоматически.
  _i3.Future<_i33.AttachmentBytes> downloadAttachment({
    required String mxcUrl,
  }) => caller.callServerEndpoint<_i33.AttachmentBytes>(
    'messenger',
    'downloadAttachment',
    {'mxcUrl': mxcUrl},
  );

  /// **TASK19 Chunk 2**: скачать thumbnail (scaled preview) media-файла.
  /// Synapse генерирует on-demand при первом запросе + кэширует. Default
  /// `width`/`height = 400` (`AttachmentService.kThumbnailMaxDim`),
  /// `method = scale` (preserves aspect). Authenticated Media через
  /// caller's matrix token. Используется SDK для chat bubble preview —
  /// fast load, low bandwidth по сравнению с full download.
  _i3.Future<_i33.AttachmentBytes> downloadAttachmentThumbnail({
    required String mxcUrl,
    int? width,
    int? height,
  }) => caller.callServerEndpoint<_i33.AttachmentBytes>(
    'messenger',
    'downloadAttachmentThumbnail',
    {
      'mxcUrl': mxcUrl,
      'width': width,
      'height': height,
    },
  );

  /// Получить страницу истории сообщений из комнаты.
  /// `viewerMessengerUserId` берётся из authenticated session.
  ///
  /// Backward-pagination через Matrix `dir=b`: первая страница
  /// (`fromToken == null`) — 50 наиболее свежих; следующие
  /// (`fromToken == prevPage.nextToken`) — OLDER страницы.
  /// `nextToken == null` означает «история закончилась».
  ///
  /// TASK15: возвращаем [MessengerMessageListPage] с tokens (на TASK09
  /// был просто `List` без pagination — закрыто с приходом SDK
  /// `MessagesController.loadMore`).
  _i3.Future<_i34.MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    required int limit,
  }) => caller.callServerEndpoint<_i34.MessengerMessageListPage>(
    'messenger',
    'listMessages',
    {
      'roomId': roomId,
      'fromToken': fromToken,
      'limit': limit,
    },
  );

  /// **TASK82**: страница ленты ТРЕДА задачи (ответы на якорь
  /// `threadRootEventId`). Пагинация — как у [listMessages] (`dir=b`,
  /// `fromToken` = `nextToken` предыдущей страницы, `nextToken == null` →
  /// тред дочитан); на последней странице в конце приходит сам якорь.
  ///
  /// Членство в комнате enforce-ится Matrix-токеном вызывающего (Matrix
  /// отклоняет не-членов 403) — тем же путём, что [listMessages].
  _i3.Future<_i34.MessengerMessageListPage> listThreadMessages({
    required int roomId,
    required String threadRootEventId,
    String? fromToken,
    required int limit,
  }) => caller.callServerEndpoint<_i34.MessengerMessageListPage>(
    'messenger',
    'listThreadMessages',
    {
      'roomId': roomId,
      'threadRootEventId': threadRootEventId,
      'fromToken': fromToken,
      'limit': limit,
    },
  );

  /// **B17 search**: keyword-поиск по сообщениям одной комнаты через
  /// Matrix `/search` endpoint. Возвращает up to `limit` matched
  /// сообщений отсортированных по `recent` (newest first).
  ///
  /// Membership enforce-ится caller's matrix token (Matrix-side reject
  /// non-members с 403). Empty/short query → пустой list (no DoS).
  _i3.Future<List<_i21.MessengerMessage>> searchMessages({
    required int roomId,
    required String query,
    required int limit,
  }) => caller.callServerEndpoint<List<_i21.MessengerMessage>>(
    'messenger',
    'searchMessages',
    {
      'roomId': roomId,
      'query': query,
      'limit': limit,
    },
  );

  /// **B17 phase 3**: кросс-room keyword-поиск по сообщениям ВСЕХ комнат
  /// viewer-а через серверный `message_index` (case-insensitive ILIKE,
  /// корректно для кириллицы). Каждый результат несёт свой
  /// `roomId`/`matrixRoomId` — клиент группирует/навигирует по комнате.
  /// Empty/short query → пусто.
  ///
  /// **Замена Synapse FTS** (см. [MatrixMessageService.searchAllMessagesIndexed]):
  /// Synapse postgres в C-locale case-fold-ит только ASCII, не кириллицу,
  /// поэтому старый Matrix `/search`-путь промахивался мимо сообщений с
  /// другим регистром. Старый [MatrixMessageService.searchAllMessages]
  /// оставлен в коде, но endpoint теперь идёт через индекс.
  _i3.Future<List<_i21.MessengerMessage>> searchAllMessages({
    required String query,
    required int limit,
  }) => caller.callServerEndpoint<List<_i21.MessengerMessage>>(
    'messenger',
    'searchAllMessages',
    {
      'query': query,
      'limit': limit,
    },
  );

  /// Пометить сообщения комнаты прочитанными до `matrixEventId`
  /// включительно (TASK18).
  ///
  /// Атомарный SQL UPDATE с monotonic guard: row обновляется только
  /// если `lastReadAt < now()` — старые markRead из другого device-а
  /// (с устаревшим horizon) не регрессируют его и не открывают окно
  /// для double-инкремента unreadCount следующим сообщением.
  ///
  /// Возвращает `true` если row реально обновился; `false` — older
  /// write rejected guard (другое устройство уже прочитало дальше).
  /// Idempotent: повторный вызов с тем же eventId — noop.
  _i3.Future<bool> markRead({
    required int roomId,
    required String matrixEventId,
  }) => caller.callServerEndpoint<bool>(
    'messenger',
    'markRead',
    {
      'roomId': roomId,
      'matrixEventId': matrixEventId,
    },
  );

  /// Зарегистрировать (или обновить) push-токен текущего устройства
  /// (TASK20 Chunk 3). SDK зовёт на старте app + при token rotation
  /// FCM / APNs.
  ///
  /// **Idempotent**: upsert по unique `(pushToken, pushService)`. Повторный
  /// вызов с теми же `(token, service)` обновляет `lastSeenAt`,
  /// `appVersion`, `deviceModel`, etc.
  ///
  /// `productExternalKey` опциональный — для standalone Chatista
  /// можно null; для embedded SDK customer-app передаёт свой product.
  /// Resolves в `productId` через `Product.externalKey`.
  _i3.Future<_i35.DeviceRegistration> registerDevice({
    required _i16.DevicePlatform platform,
    required String pushToken,
    required _i36.PushService pushService,
    required String locale,
    required String appVersion,
    String? deviceModel,
    String? productExternalKey,
  }) => caller.callServerEndpoint<_i35.DeviceRegistration>(
    'messenger',
    'registerDevice',
    {
      'platform': platform,
      'pushToken': pushToken,
      'pushService': pushService,
      'locale': locale,
      'appVersion': appVersion,
      'deviceModel': deviceModel,
      'productExternalKey': productExternalKey,
    },
  );

  /// Удалить регистрацию push-токена (TASK20 Chunk 3). SDK зовёт при
  /// logout / `MessengerRuntime.dispose`. Возвращает `true` если row
  /// существовала и удалена; `false` — если token не найден
  /// (idempotent — multiple unregister calls безопасны).
  ///
  /// **Authorization**: для MVP не проверяем что вызывающий —
  /// owner устройства. На production можно добавить guard «delete
  /// only if `messengerUserId == authenticated`», но edge case:
  /// один и тот же FCM token redirected на другой messengerUserId
  /// (multi-account на одном device). Сейчас — простое delete.
  _i3.Future<bool> unregisterDevice({required String pushToken}) =>
      caller.callServerEndpoint<bool>(
        'messenger',
        'unregisterDevice',
        {'pushToken': pushToken},
      );

  _i3.Stream<_i27.MessengerEvent> userEventStream({
    List<String>? capabilities,
    List<String>? knownEventTypes,
  }) =>
      caller.callStreamingServerEndpoint<
        _i3.Stream<_i27.MessengerEvent>,
        _i27.MessengerEvent
      >(
        'messenger',
        'userEventStream',
        {
          'capabilities': capabilities,
          'knownEventTypes': knownEventTypes,
        },
        {},
      );

  /// Список комнат, в которых состоит текущий юзер. Только из локальной
  /// БД (sync-loop держит lastMessageAt/Body в актуальном состоянии).
  /// Параметры `state` / `search` / `includeArchived` заложены в
  /// сигнатуре, но фильтрация — TASK42 (UX); сейчас работают только
  /// `productId` + `cursor`.
  _i3.Future<List<_i9.RoomSummary>> listRooms({
    int? productId,
    _i37.RoomState? state,
    String? search,
    bool? includeArchived,
    required int limit,
    String? cursor,
  }) => caller.callServerEndpoint<List<_i9.RoomSummary>>(
    'messenger',
    'listRooms',
    {
      'productId': productId,
      'state': state,
      'search': search,
      'includeArchived': includeArchived,
      'limit': limit,
      'cursor': cursor,
    },
  );

  /// **issue #46** — страница комнат вместе с `nextCursor`.
  ///
  /// Отличие от [listRooms] ровно одно: клиент узнаёт, есть ли ещё
  /// комнаты. Без этого дойти дальше первой страницы было нельзя —
  /// курсор строился только внутри сервера, наружу не выходил, и список
  /// чатов молча обрезался на 50-й комнате вместе с папками и бейджами.
  ///
  /// SDK крутит этот метод в цикле до `nextCursor == null` (полный синк
  /// списка комнат), поэтому [listRooms] не тронут — по нему продолжают
  /// ходить клиенты в поле.
  _i3.Future<_i38.RoomListPage> listRoomsPage({
    int? productId,
    _i37.RoomState? state,
    String? search,
    bool? includeArchived,
    required int limit,
    String? cursor,
  }) => caller.callServerEndpoint<_i38.RoomListPage>(
    'messenger',
    'listRoomsPage',
    {
      'productId': productId,
      'state': state,
      'search': search,
      'includeArchived': includeArchived,
      'limit': limit,
      'cursor': cursor,
    },
  );

  /// Подробности конкретной комнаты + первые 30 участников + viewer-роль.
  /// Если caller не состоит в membership — `RoomUnavailableException`
  /// (anti-enumeration).
  _i3.Future<_i39.RoomDetails> getRoom({required int roomId}) =>
      caller.callServerEndpoint<_i39.RoomDetails>(
        'messenger',
        'getRoom',
        {'roomId': roomId},
      );

  /// Идемпотентно создать direct chat caller↔peer. Заменяет старый
  /// `getOrCreateDirect`. Cross-tenant / non-existent peer →
  /// `PeerUnavailableException` (anti-enumeration).
  _i3.Future<_i39.RoomDetails> createDirect({
    required int peerMessengerUserId,
  }) => caller.callServerEndpoint<_i39.RoomDetails>(
    'messenger',
    'createDirect',
    {'peerMessengerUserId': peerMessengerUserId},
  );

  /// **Найти пользователя по email** — точное совпадение email +
  /// tenantExternalKey. Возвращает [RoomParticipant] (с role='member'
  /// — не имеет смысла для search context, но reuse DTO избегает
  /// новой spy.yaml).
  ///
  /// Используется UI для chat creation flow: тестер вводит email
  /// собеседника → server lookup → confirmation card с displayName +
  /// matrixUserId → createDirect(messengerUserId).
  ///
  /// **Errors**:
  ///   * Email отсутствует в EmailAccount → [PeerUnavailableException]
  ///     (anti-enumeration: одинаковая ошибка для unknown email AND
  ///     user-not-yet-messengered).
  ///   * EmailAccount существует но MessengerUser ещё не создан
  ///     (signedUp но не вызывал messenger.session()) → тоже
  ///     PeerUnavailableException.
  _i3.Future<_i31.RoomParticipant> findUserByEmail({
    required String email,
    required String tenantExternalKey,
  }) => caller.callServerEndpoint<_i31.RoomParticipant>(
    'messenger',
    'findUserByEmail',
    {
      'email': email,
      'tenantExternalKey': tenantExternalKey,
    },
  );

  /// **Список «знакомых»** — все participants комнат, в которых я состою
  /// (direct + group), distinct по `messengerUserId`, без self и без
  /// ghost-users. Используется UI для default-списка в picker-ах
  /// (создание группы, добавление участника) ДО любого ввода в поиск.
  ///
  /// Сортировка: по `displayName ASC` (case-insensitive, кириллица
  /// поддерживается стандартным compare).
  ///
  /// Privacy: НЕ раскрывает справочник всех зарегистрированных
  /// пользователей tenant-а — только тех, с кем у меня уже есть хоть
  /// одна общая комната. Это естественный «адресбук»: чтобы оказаться
  /// в списке, надо быть приглашённым / поприглашать в личку.
  ///
  /// Возвращает пустой list если у caller нет ни одной комнаты или нет
  /// peer-ов в комнатах.
  _i3.Future<List<_i31.RoomParticipant>> listKnownContacts() =>
      caller.callServerEndpoint<List<_i31.RoomParticipant>>(
        'messenger',
        'listKnownContacts',
        {},
      );

  /// **Поиск пользователей** — по email (exact-match если в строке `@`)
  /// или по nickname/displayName (ILIKE substring). Используется UI для
  /// chat-create flow когда тестер не помнит точный email или хочет
  /// найти по имени.
  ///
  /// **Возвращает**: list of [RoomParticipant], отсортирован по
  /// (displayName) ASC, обрезан до [limit] (default 20).
  ///
  /// **Filters out**:
  ///   * Ghost users (null matrixAccessTokenEncrypted / @stub- ids).
  ///   * Cross-tenant users (always scoped к caller's tenant).
  ///   * Самого caller-а (нельзя себе DM написать через search).
  ///
  /// **Edge cases**:
  ///   * Empty query → пустой list (no DoS surface).
  ///   * Query короче 2 символов → пустой list (anti-fishing).
  _i3.Future<List<_i31.RoomParticipant>> searchUsers({
    required String query,
    required int limit,
    required String tenantExternalKey,
  }) => caller.callServerEndpoint<List<_i31.RoomParticipant>>(
    'messenger',
    'searchUsers',
    {
      'query': query,
      'limit': limit,
      'tenantExternalKey': tenantExternalKey,
    },
  );

  /// **Пригласить пользователя в существующую комнату**. Caller должен
  /// быть member комнаты (server проверяет через RoomService). Target
  /// получает Matrix invite + auto-join.
  ///
  /// Идемпотентно: если target уже в комнате — no-op.
  ///
  /// **Errors**:
  ///   * Room не существует / caller не member → [RoomUnavailableException].
  ///   * Target не существует / cross-tenant → [PeerUnavailableException].
  _i3.Future<void> inviteToRoom({
    required int roomId,
    required int targetMessengerUserId,
  }) => caller.callServerEndpoint<void>(
    'messenger',
    'inviteToRoom',
    {
      'roomId': roomId,
      'targetMessengerUserId': targetMessengerUserId,
    },
  );

  /// Создать group-комнату. Caller получает role `owner`; members
  /// silently dedup-ятся, caller silently удаляется из списка если
  /// был добавлен. Cross-tenant / non-existent member →
  /// `PeerUnavailableException`.
  _i3.Future<_i39.RoomDetails> createGroup({
    required String name,
    required List<int> memberMessengerUserIds,
    int? productId,
  }) => caller.callServerEndpoint<_i39.RoomDetails>(
    'messenger',
    'createGroup',
    {
      'name': name,
      'memberMessengerUserIds': memberMessengerUserIds,
      'productId': productId,
    },
  );

  /// Идемпотентно создать / найти комнату для продуктовой сущности
  /// `(productExternalKey, entityType, entityId)`. При cache hit caller
  /// auto-join-ится в membership, если ещё не там.
  _i3.Future<_i39.RoomDetails> getOrCreateProductRoom({
    required String productExternalKey,
    required String entityType,
    required String entityId,
    required _i40.RoomType roomType,
  }) => caller.callServerEndpoint<_i39.RoomDetails>(
    'messenger',
    'getOrCreateProductRoom',
    {
      'productExternalKey': productExternalKey,
      'entityType': entityType,
      'entityId': entityId,
      'roomType': roomType,
    },
  );

  /// Поддержка по `contextId`. На MVP — частный случай productRoom
  /// с `entityType='support_ticket'` без pre-defined operator-а
  /// (TASK29 / customer config добавит).
  _i3.Future<_i39.RoomDetails> openSupportChat({
    required String productExternalKey,
    required String contextId,
  }) => caller.callServerEndpoint<_i39.RoomDetails>(
    'messenger',
    'openSupportChat',
    {
      'productExternalKey': productExternalKey,
      'contextId': contextId,
    },
  );

  /// **TASK57 фаза 1**: «Мои обращения» — список тикетов текущего пользователя
  /// со статусами (open/closed) и ссылкой на GitHub issue (если заведён).
  _i3.Future<List<_i41.TicketView>> listMyTickets() =>
      caller.callServerEndpoint<List<_i41.TicketView>>(
        'messenger',
        'listMyTickets',
        {},
      );

  /// **TASK55 итер.1**: heartbeat активности (SDK шлёт с троттлом ≥60с
  /// в foreground). Обновляет `lastActiveAt` вызывающего.
  _i3.Future<void> presenceHeartbeat() => caller.callServerEndpoint<void>(
    'messenger',
    'presenceHeartbeat',
    {},
  );

  /// **TASK55 итер.1**: batch last-seen (≤50 id). Отдаёт только по
  /// пользователям с общей комнатой (тот же tenant); боты/чужие id тихо
  /// отбрасываются. `lastActiveAt` огрублён до минуты. НЕ путать с
  /// [getPresence] (foreground-кэш для UI «онлайн сейчас», single-id).
  _i3.Future<List<_i42.PresenceInfo>> getLastSeen({
    required List<int> userIds,
  }) => caller.callServerEndpoint<List<_i42.PresenceInfo>>(
    'messenger',
    'getLastSeen',
    {'userIds': userIds},
  );

  /// **TASK55 итер.2b**: подписаться на presence целей (≤50; идемпотентно,
  /// TTL ~5 мин — SDK повторяет при открытом чате). Возвращает актуальный
  /// снапшот. События придут в userEventStream при объявленной capability
  /// `presence`.
  _i3.Future<List<_i42.PresenceInfo>> subscribePresence({
    required List<int> userIds,
  }) => caller.callServerEndpoint<List<_i42.PresenceInfo>>(
    'messenger',
    'subscribePresence',
    {'userIds': userIds},
  );

  /// **TASK62**: список папок текущего пользователя (с roomIds).
  _i3.Future<List<_i43.ChatFolderView>> listChatFolders() =>
      caller.callServerEndpoint<List<_i43.ChatFolderView>>(
        'messenger',
        'listChatFolders',
        {},
      );

  /// **TASK62**: создать папку (имя 1..64, уникально per user, ≤50 папок).
  _i3.Future<_i43.ChatFolderView> createChatFolder({required String name}) =>
      caller.callServerEndpoint<_i43.ChatFolderView>(
        'messenger',
        'createChatFolder',
        {'name': name},
      );

  /// **TASK62**: переименовать свою папку.
  _i3.Future<_i43.ChatFolderView> renameChatFolder({
    required int folderId,
    required String name,
  }) => caller.callServerEndpoint<_i43.ChatFolderView>(
    'messenger',
    'renameChatFolder',
    {
      'folderId': folderId,
      'name': name,
    },
  );

  /// **TASK62**: удалить свою папку (комнаты не затрагиваются).
  _i3.Future<void> deleteChatFolder({required int folderId}) =>
      caller.callServerEndpoint<void>(
        'messenger',
        'deleteChatFolder',
        {'folderId': folderId},
      );

  /// **TASK62**: добавить комнату в папку (идемпотентно; только свои
  /// папка и комната).
  _i3.Future<void> addRoomToChatFolder({
    required int folderId,
    required int roomId,
  }) => caller.callServerEndpoint<void>(
    'messenger',
    'addRoomToChatFolder',
    {
      'folderId': folderId,
      'roomId': roomId,
    },
  );

  /// **TASK62**: убрать комнату из папки (идемпотентно).
  _i3.Future<void> removeRoomFromChatFolder({
    required int folderId,
    required int roomId,
  }) => caller.callServerEndpoint<void>(
    'messenger',
    'removeRoomFromChatFolder',
    {
      'folderId': folderId,
      'roomId': roomId,
    },
  );

  /// **TASK68**: дефолтный чат «Избранное» из коробки. Идемпотентно —
  /// первый вызов создаёт self-комнату, последующие возвращают её же
  /// (самый ранний self-чат владельца). Клиент дёргает при входе в раздел
  /// «Избранное», чтобы там всегда было куда написать.
  ///
  /// Self-чат — обычная Matrix-комната с единственным участником, поэтому
  /// синхронизация между устройствами идёт штатным `/sync` (см. TASK68 §4).
  _i3.Future<_i39.RoomDetails> getOrCreateSelfRoom() =>
      caller.callServerEndpoint<_i39.RoomDetails>(
        'messenger',
        'getOrCreateSelfRoom',
        {},
      );

  /// **TASK68**: создать новый именованный раздел «Избранного»
  /// («программирование», «файлообмен», «заметки»).
  ///
  /// Throws [StateError] с кодом в тексте: `saved_chat_name_invalid`
  /// (пустое / длиннее [SavedChatPolicy.maxNameLength]), `saved_chat_limit`
  /// (потолок [SavedChatPolicy.maxSavedChatsPerUser] разделов),
  /// `saved_chat_name_taken` (такой раздел уже есть).
  _i3.Future<_i39.RoomDetails> createSavedChat({required String name}) =>
      caller.callServerEndpoint<_i39.RoomDetails>(
        'messenger',
        'createSavedChat',
        {'name': name},
      );

  /// **TASK68**: все self-чаты текущего пользователя — теми же
  /// [RoomSummary], что и общий список чатов (одинаковые строки в UI).
  /// Пустой список, если пользователь ещё не заходил в «Избранное».
  _i3.Future<List<_i9.RoomSummary>> listSavedChats() =>
      caller.callServerEndpoint<List<_i9.RoomSummary>>(
        'messenger',
        'listSavedChats',
        {},
      );

  /// **TASK68**: задать TTL автоочистки раздела. `ttlSeconds == null`
  /// (или `<= 0`) — выключить. Свип [SavedCleanupFutureCall] сносит
  /// сообщения старше TTL, **не трогая закреплённые**.
  ///
  /// Throws [RoomUnavailableException] (не участник / нет комнаты) или
  /// [StateError] с кодом `saved_chat_ttl_unsupported` (комната не
  /// «Избранное») / `saved_chat_ttl_invalid` (TTL вне допустимых границ).
  _i3.Future<_i39.RoomDetails> setRoomAutoCleanupTtl({
    required int roomId,
    int? ttlSeconds,
  }) => caller.callServerEndpoint<_i39.RoomDetails>(
    'messenger',
    'setRoomAutoCleanupTtl',
    {
      'roomId': roomId,
      'ttlSeconds': ttlSeconds,
    },
  );

  /// **TASK52**: отношение текущего пользователя к другому (для UI:
  /// кнопки контакта/блокировки, интро-карточка).
  _i3.Future<_i44.ContactRelation> getContactRelation({
    required int otherMessengerUserId,
  }) => caller.callServerEndpoint<_i44.ContactRelation>(
    'messenger',
    'getContactRelation',
    {'otherMessengerUserId': otherMessengerUserId},
  );

  /// **TASK52**: добавить пользователя в контакты вручную (направленная
  /// связь me→contact). Даёт contact-у пройти мой гейт «кто может
  /// писать» (симметричный trust).
  _i3.Future<void> addContact({required int contactMessengerUserId}) =>
      caller.callServerEndpoint<void>(
        'messenger',
        'addContact',
        {'contactMessengerUserId': contactMessengerUserId},
      );

  /// **TASK52**: убрать из контактов (снять мою связь). Существующий
  /// direct не закрывается.
  _i3.Future<void> removeContact({required int contactMessengerUserId}) =>
      caller.callServerEndpoint<void>(
        'messenger',
        'removeContact',
        {'contactMessengerUserId': contactMessengerUserId},
      );

  /// **TASK52 (§3B.8a)**: заблокировать пользователя.
  _i3.Future<void> blockUser({required int targetMessengerUserId}) =>
      caller.callServerEndpoint<void>(
        'messenger',
        'blockUser',
        {'targetMessengerUserId': targetMessengerUserId},
      );

  /// **TASK52 (§3B.8a)**: разблокировать.
  _i3.Future<void> unblockUser({required int targetMessengerUserId}) =>
      caller.callServerEndpoint<void>(
        'messenger',
        'unblockUser',
        {'targetMessengerUserId': targetMessengerUserId},
      );

  /// **TASK52 (§8)**: отправить заявку «показать визитку» пользователю с
  /// whoCanMessageMe='contacts'. Идемпотентна; молчаливо «успешна» при
  /// блокировке/несуществующем (anti-enumeration). Cooldown/дневной
  /// лимит → RateLimitExceededException.
  _i3.Future<void> sendContactRequest({
    required int toMessengerUserId,
    String? note,
  }) => caller.callServerEndpoint<void>(
    'messenger',
    'sendContactRequest',
    {
      'toMessengerUserId': toMessengerUserId,
      'note': note,
    },
  );

  /// **TASK52**: мои входящие заявки (pending) с полями отправителей.
  _i3.Future<List<_i45.ContactRequestView>> listIncomingContactRequests() =>
      caller.callServerEndpoint<List<_i45.ContactRequestView>>(
        'messenger',
        'listIncomingContactRequests',
        {},
      );

  /// **TASK52**: принять заявку → взаимный ContactLink + direct-чат.
  /// Возврат — RoomDetails созданной комнаты. Заявка не найдена/не моя/
  /// не pending → PeerUnavailable (anti-enumeration).
  _i3.Future<_i39.RoomDetails> acceptContactRequest({required int requestId}) =>
      caller.callServerEndpoint<_i39.RoomDetails>(
        'messenger',
        'acceptContactRequest',
        {'requestId': requestId},
      );

  /// **TASK52**: отклонить заявку (запускает cooldown; отправителя не
  /// уведомляем).
  _i3.Future<void> declineContactRequest({required int requestId}) =>
      caller.callServerEndpoint<void>(
        'messenger',
        'declineContactRequest',
        {'requestId': requestId},
      );

  /// **TASK52 итер.2**: выдать эфемерный trust-токен (QR / «Рядом» /
  /// инвайт-ссылка). Единый механизм — потребитель различается только
  /// [kind]. Токен встраивается в QR/ссылку/BLE; встречный гасит его
  /// через [redeemTrustToken] → взаимный контакт.
  _i3.Future<_i46.TrustTokenIssued> issueTrustToken({
    required _i47.TrustTokenKind kind,
  }) => caller.callServerEndpoint<_i46.TrustTokenIssued>(
    'messenger',
    'issueTrustToken',
    {'kind': kind},
  );

  /// **TASK52 итер.2**: погасить trust-токен → взаимный ContactLink.
  /// Возврат — с кем теперь на связи (id + публичные поля, для открытия
  /// direct-чата/интро-карточки), либо null на любой невалидный исход
  /// (нет токена / истёк / исчерпан / свой / чужой tenant — неотличимо,
  /// anti-enumeration).
  _i3.Future<_i48.TrustRedeemResult?> redeemTrustToken({
    required String token,
  }) => caller.callServerEndpoint<_i48.TrustRedeemResult?>(
    'messenger',
    'redeemTrustToken',
    {'token': token},
  );

  /// **TASK52 итер.2**: отозвать мои инвайт-ссылки (старые перестают
  /// работать; следующий issueTrustToken(invite) выдаст новую).
  _i3.Future<void> revokeInviteTokens() => caller.callServerEndpoint<void>(
    'messenger',
    'revokeInviteTokens',
    {},
  );

  /// **TASK52 итер.2**: подтвердить близость с peer («Рядом»). Требует
  /// ВЗАИМНОГО тапа в окне 60с — BLE недоверенное. matched=true →
  /// взаимный контакт (можно открыть чат); matched=false → ждём ответный
  /// тап peer-а.
  _i3.Future<_i49.NearbyConfirmResult> confirmNearby({
    required int peerMessengerUserId,
  }) => caller.callServerEndpoint<_i49.NearbyConfirmResult>(
    'messenger',
    'confirmNearby',
    {'peerMessengerUserId': peerMessengerUserId},
  );

  /// **TASK52**: визитка пользователя глазами вызывающего — contacts-only
  /// поля вырезаны, если нет trust-связи (итер.1 — общая комната).
  /// null = визитки нет; несуществующий id / чужой tenant — тоже null
  /// (anti-enumeration). Rate-limit 120/мин на вызывающего.
  _i3.Future<_i50.ContactCardInfo?> getContactCard({
    required int messengerUserId,
  }) => caller.callServerEndpoint<_i50.ContactCardInfo?>(
    'messenger',
    'getContactCard',
    {'messengerUserId': messengerUserId},
  );

  /// **TASK52**: своя визитка целиком (включая contactsOnlyFields) —
  /// для редактора. null = ещё не создана.
  _i3.Future<_i51.ContactCard?> getMyContactCard() =>
      caller.callServerEndpoint<_i51.ContactCard?>(
        'messenger',
        'getMyContactCard',
        {},
      );

  /// **TASK52**: сохранить свою визитку (upsert). id/messengerUserId
  /// из [card] игнорируются — владелец всегда caller.
  _i3.Future<_i51.ContactCard> setMyContactCard({
    required _i51.ContactCard card,
  }) => caller.callServerEndpoint<_i51.ContactCard>(
    'messenger',
    'setMyContactCard',
    {'card': card},
  );

  /// **TASK52**: удалить свою визитку. Идемпотентно.
  _i3.Future<void> deleteMyContactCard() => caller.callServerEndpoint<void>(
    'messenger',
    'deleteMyContactCard',
    {},
  );

  /// **TASK63**: профиль контакта глазами текущего пользователя —
  /// публичные поля + приватные alias/заметка/метки viewer-а.
  _i3.Future<_i52.ContactProfileView> getContactProfile({
    required int contactMessengerUserId,
  }) => caller.callServerEndpoint<_i52.ContactProfileView>(
    'messenger',
    'getContactProfile',
    {'contactMessengerUserId': contactMessengerUserId},
  );

  /// **TASK63**: задать «своё имя» и/или заметку. null = не менять,
  /// пустая строка = очистить.
  _i3.Future<_i52.ContactProfileView> setContactMeta({
    required int contactMessengerUserId,
    String? customName,
    String? note,
  }) => caller.callServerEndpoint<_i52.ContactProfileView>(
    'messenger',
    'setContactMeta',
    {
      'contactMessengerUserId': contactMessengerUserId,
      'customName': customName,
      'note': note,
    },
  );

  /// **TASK63**: метки текущего пользователя.
  _i3.Future<List<_i53.ContactLabel>> listContactLabels() =>
      caller.callServerEndpoint<List<_i53.ContactLabel>>(
        'messenger',
        'listContactLabels',
        {},
      );

  /// **TASK63 итер.3**: все назначения меток текущего пользователя
  /// (для точек/счётчиков/клиентского фильтра на экране «Люди»).
  _i3.Future<List<_i54.ContactLabelAssignment>> listContactLabelAssignments() =>
      caller.callServerEndpoint<List<_i54.ContactLabelAssignment>>(
        'messenger',
        'listContactLabelAssignments',
        {},
      );

  /// **TASK63**: создать метку (имя 1..32, уникально per user, ≤100).
  _i3.Future<_i53.ContactLabel> createContactLabel({
    required String name,
    String? colorHex,
  }) => caller.callServerEndpoint<_i53.ContactLabel>(
    'messenger',
    'createContactLabel',
    {
      'name': name,
      'colorHex': colorHex,
    },
  );

  /// **TASK63**: переименовать/перекрасить метку.
  _i3.Future<_i53.ContactLabel> renameContactLabel({
    required int labelId,
    required String name,
    String? colorHex,
  }) => caller.callServerEndpoint<_i53.ContactLabel>(
    'messenger',
    'renameContactLabel',
    {
      'labelId': labelId,
      'name': name,
      'colorHex': colorHex,
    },
  );

  /// **TASK63**: удалить метку (снимется со всех контактов).
  _i3.Future<void> deleteContactLabel({required int labelId}) =>
      caller.callServerEndpoint<void>(
        'messenger',
        'deleteContactLabel',
        {'labelId': labelId},
      );

  /// **TASK63**: повесить/снять метку с контакта (идемпотентно).
  _i3.Future<void> setContactLabelAssigned({
    required int labelId,
    required int contactMessengerUserId,
    required bool assigned,
  }) => caller.callServerEndpoint<void>(
    'messenger',
    'setContactLabelAssigned',
    {
      'labelId': labelId,
      'contactMessengerUserId': contactMessengerUserId,
      'assigned': assigned,
    },
  );

  /// **TASK63**: контакты с меткой (директория; имена уже с alias-ами).
  _i3.Future<List<_i31.RoomParticipant>> listContactsByLabel({
    required int labelId,
  }) => caller.callServerEndpoint<List<_i31.RoomParticipant>>(
    'messenger',
    'listContactsByLabel',
    {'labelId': labelId},
  );

  /// **TASK45 фаза 1**: объектовая комната продукта. Идемпотентна по
  /// `(product, 'object', objectId)`. Имя комнаты = [name] (имя объекта,
  /// задаётся хостом-продуктом) — консистентно в `rooms.name` и Matrix
  /// `m.room.name`. Участники — [memberMessengerUserIds] (ответственный +
  /// куратор, резолвит titan) + бот продукта. Команда NSG НЕ добавляется
  /// (только по эскалации, фаза 2). Caller — создатель (owner).
  ///
  /// Обычно вызывается server-to-server из titan (сессия caller-а), но
  /// сигнатура — обычный аутентифицированный messenger-RPC.
  _i3.Future<_i39.RoomDetails> getOrCreateObjectRoom({
    required String productExternalKey,
    required String objectId,
    required String name,
    required List<int> memberMessengerUserIds,
  }) => caller.callServerEndpoint<_i39.RoomDetails>(
    'messenger',
    'getOrCreateObjectRoom',
    {
      'productExternalKey': productExternalKey,
      'objectId': objectId,
      'name': name,
      'memberMessengerUserIds': memberMessengerUserIds,
    },
  );

  /// **TASK43**: состав операторской команды продукта. Доступно только
  /// участникам команды (людям И боту продукта — бот ходит по своему
  /// bot-токену, который резолвится в его messengerUserId): используется
  /// SDK-экраном «Команда поддержки» (гейт по не-исключению) и RPC бота
  /// (список operator-MUID).
  ///
  /// Не-участник → [NotSupportTeamMemberException] (anti-enumeration: не
  /// раскрываем ни существование команды, ни её состав).
  _i3.Future<_i55.SupportTeamView> getSupportTeam({
    required String productExternalKey,
  }) => caller.callServerEndpoint<_i55.SupportTeamView>(
    'messenger',
    'getSupportTeam',
    {'productExternalKey': productExternalKey},
  );

  /// **TASK76**: создать команду поддержки продукта self-service —
  /// СОЗДАТЕЛЬ становится владельцем (`owner`) и дальше управляет составом,
  /// назначает других админов и подключает бота (модель «создатель канала =
  /// админ», как у бот-интеграций комнат). Для наших продуктов команды
  /// создаёт env-сид при старте — этот RPC для сторонних проектов.
  ///
  /// Throws: [ProductNotFoundForCallerException] (нет продукта в tenant-е
  /// caller-а), [NotSupportTeamMemberException] (команда уже есть и caller
  /// не в ней — anti-enumeration). Идемпотентно для участника существующей
  /// команды (вернёт её view).
  _i3.Future<_i55.SupportTeamView> createSupportTeam({
    required String productExternalKey,
  }) => caller.callServerEndpoint<_i55.SupportTeamView>(
    'messenger',
    'createSupportTeam',
    {'productExternalKey': productExternalKey},
  );

  /// **TASK76**: сменить роль участника команды (`owner` ↔ `member`) —
  /// только владелец. «Назначение других администраторов»: повышенный
  /// участник тоже управляет составом. Понизить последнего владельца
  /// нельзя ([LastOwnerCannotDemoteException]). Возвращает обновлённый view.
  _i3.Future<_i55.SupportTeamView> setSupportTeamMemberRole({
    required String productExternalKey,
    required int targetMessengerUserId,
    required _i56.SupportTeamRole role,
  }) => caller.callServerEndpoint<_i55.SupportTeamView>(
    'messenger',
    'setSupportTeamMemberRole',
    {
      'productExternalKey': productExternalKey,
      'targetMessengerUserId': targetMessengerUserId,
      'role': role,
    },
  );

  /// **TASK43**: добавить оператора в команду по email — только владелец
  /// команды (`owner`). Возвращает обновлённый [SupportTeamView].
  ///
  /// Throws: [NotSupportTeamMemberException] (команды нет / caller не в
  /// ней), [NotSupportTeamOwnerException] (caller не owner),
  /// [PeerUnavailableException] (email не резолвится — оператор ещё не
  /// входил / нет аккаунта).
  _i3.Future<_i55.SupportTeamView> addSupportTeamMember({
    required String productExternalKey,
    required String email,
    int? tier,
  }) => caller.callServerEndpoint<_i55.SupportTeamView>(
    'messenger',
    'addSupportTeamMember',
    {
      'productExternalKey': productExternalKey,
      'email': email,
      'tier': tier,
    },
  );

  /// **TASK48**: сменить тир (уровень) участника команды — только owner.
  /// `tier` 1 = фронт-линия, 2 = эскалация. Затрагивает БУДУЩИЕ support-
  /// комнаты и эскалацию; уже открытые не трогаются. Возвращает обновлённый
  /// view. Throws как [addSupportTeamMember] (owner-gated).
  _i3.Future<_i55.SupportTeamView> setSupportTeamMemberTier({
    required String productExternalKey,
    required int targetMessengerUserId,
    required int tier,
  }) => caller.callServerEndpoint<_i55.SupportTeamView>(
    'messenger',
    'setSupportTeamMemberTier',
    {
      'productExternalKey': productExternalKey,
      'targetMessengerUserId': targetMessengerUserId,
      'tier': tier,
    },
  );

  /// **TASK48 iter2**: порог авто-эскалации команды в минутах — только
  /// owner. Читается sweep-джобом (`SupportEscalationSweepFutureCall`).
  /// Клампится сервером в [1, 10080]. Возвращает обновлённый view.
  _i3.Future<_i55.SupportTeamView> setSupportTeamTimeout({
    required String productExternalKey,
    required int minutes,
  }) => caller.callServerEndpoint<_i55.SupportTeamView>(
    'messenger',
    'setSupportTeamTimeout',
    {
      'productExternalKey': productExternalKey,
      'minutes': minutes,
    },
  );

  /// **TASK43**: убрать оператора из команды по messengerUserId — только
  /// владелец. Нельзя убрать последнего owner-а
  /// ([LastOwnerCannotDemoteException]). Возвращает обновлённый view.
  _i3.Future<_i55.SupportTeamView> removeSupportTeamMember({
    required String productExternalKey,
    required int targetMessengerUserId,
  }) => caller.callServerEndpoint<_i55.SupportTeamView>(
    'messenger',
    'removeSupportTeamMember',
    {
      'productExternalKey': productExternalKey,
      'targetMessengerUserId': targetMessengerUserId,
    },
  );

  /// **TASK45 фаза 1 п.5**: каталог ВСЕХ объектовых комнат продукта
  /// (entityType='object'), включая те, где caller ещё НЕ участник —
  /// команда NSG видит объектовые чаты «по запросу», не входя в них по
  /// умолчанию (см. §3.10). Gated: caller — член [SupportTeam] продукта,
  /// иначе [NotSupportTeamMemberException] (anti-enumeration).
  ///
  /// Каждая запись несёт флаг [ProductObjectRoom.viewerIsMember] («я уже
  /// вошёл?») — UI по нему решает: открыть сразу или сперва
  /// [joinProductRoom].
  _i3.Future<List<_i57.ProductObjectRoom>> listProductObjectRooms({
    required String productExternalKey,
  }) => caller.callServerEndpoint<List<_i57.ProductObjectRoom>>(
    'messenger',
    'listProductObjectRooms',
    {'productExternalKey': productExternalKey},
  );

  /// **TASK45 фаза 1 п.5**: войти в объектовую комнату продукта (член
  /// команды добавляет себя в membership + Matrix join). Идемпотентно.
  /// history_visibility=shared → вошедший видит ВСЮ прошлую переписку.
  /// Возвращает [RoomDetails] (как getRoom).
  ///
  /// Gated: caller — член команды продукта комнаты, [roomId] — объектовая
  /// комната. Иначе [NotSupportTeamMemberException] / [RoomUnavailableException].
  _i3.Future<_i39.RoomDetails> joinProductRoom({required int roomId}) =>
      caller.callServerEndpoint<_i39.RoomDetails>(
        'messenger',
        'joinProductRoom',
        {'roomId': roomId},
      );

  /// **TASK45 фаза 1 п.5**: выйти из объектовой комнаты продукта (член
  /// команды покидает чат, когда вопрос решён). Делегирует в
  /// [RoomService.leaveRoom] (TASK42). История сохраняется — повторный
  /// вход снова покажет всю переписку.
  _i3.Future<void> leaveProductRoom({required int roomId}) =>
      caller.callServerEndpoint<void>(
        'messenger',
        'leaveProductRoom',
        {'roomId': roomId},
      );

  /// **TASK45 фаза 2**: подключить команду поддержки NSG к объектовому
  /// чату (кнопка «Обратиться к разработчикам», видна ВСЕМ участникам
  /// объектового чата). Добавляет ВСЕХ членов команды продукта в комнату
  /// (идемпотентно — уже вошедших пропускает) + системное сообщение
  /// «🛠 Подключена команда поддержки NSG» + push каждому НОВО добавленному.
  ///
  /// Доступен ЛЮБОМУ участнику комнаты. Throws:
  ///   * [RoomUnavailableException] — комната не существует / caller не
  ///     участник (anti-enumeration);
  ///   * [NotObjectRoomException] — комната не объектовая.
  _i3.Future<_i58.EscalationResult> escalateToSupportTeam({
    required int roomId,
  }) => caller.callServerEndpoint<_i58.EscalationResult>(
    'messenger',
    'escalateToSupportTeam',
    {'roomId': roomId},
  );

  /// **TASK48**: эскалировать SUPPORT-чат на следующий тир (кнопка
  /// «Позвать старшего», видна оператору-члену при
  /// `RoomDetails.canEscalateSupport`). Добавляет людей следующего непустого
  /// тира + системное сообщение + push. Конкурентно-безопасно. «Мягкие»
  /// отказы (выше никого / гонка) → no-op [EscalationResult]. Throws
  /// [RoomUnavailableException], если caller не участник комнаты.
  _i3.Future<_i58.EscalationResult> escalateSupportRoom({
    required int roomId,
  }) => caller.callServerEndpoint<_i58.EscalationResult>(
    'messenger',
    'escalateSupportRoom',
    {'roomId': roomId},
  );

  /// Заглушить комнату до момента `mutedUntil` (либо `now +
  /// muteForSeconds`). Один из двух параметров обязателен; оба
  /// одновременно — error.
  ///
  /// Для «mute навсегда» передайте `mutedUntil: RoomService
  /// .kMuteForever` (`DateTime.utc(9999, 1, 1)`).
  ///
  /// Для unmute — sugar [unmuteRoom] (или прямой вызов с обоими
  /// параметрами `null`).
  _i3.Future<void> muteRoom({
    required int roomId,
    DateTime? mutedUntil,
    int? muteForSeconds,
  }) => caller.callServerEndpoint<void>(
    'messenger',
    'muteRoom',
    {
      'roomId': roomId,
      'mutedUntil': mutedUntil,
      'muteForSeconds': muteForSeconds,
    },
  );

  /// **Персональное имя комнаты (2026-07-13)**: видит только вызывающий
  /// (membership per-viewer). Пустая строка = сброс. trim ≤64. Высший
  /// приоритет имени в списке чатов/заголовке.
  _i3.Future<void> setRoomCustomName({
    required int roomId,
    required String customName,
  }) => caller.callServerEndpoint<void>(
    'messenger',
    'setRoomCustomName',
    {
      'roomId': roomId,
      'customName': customName,
    },
  );

  /// **Write-ban (2026-07-13)**: запретить/разрешить участнику писать в
  /// комнату (остаётся читателем). [untilSeconds] = длительность от
  /// «сейчас»; null при [banned]=true — навсегда. [banned]=false —
  /// снять. Caller — admin/owner (guards в RoomAdminService).
  _i3.Future<void> setWriteBan({
    required int roomId,
    required int targetMessengerUserId,
    required bool banned,
    int? untilSeconds,
  }) => caller.callServerEndpoint<void>(
    'messenger',
    'setWriteBan',
    {
      'roomId': roomId,
      'targetMessengerUserId': targetMessengerUserId,
      'banned': banned,
      'untilSeconds': untilSeconds,
    },
  );

  /// Sugar над [muteRoom] с `mutedUntil: null`.
  _i3.Future<void> unmuteRoom({required int roomId}) =>
      caller.callServerEndpoint<void>(
        'messenger',
        'unmuteRoom',
        {'roomId': roomId},
      );

  /// Архивировать комнату для viewer-а (per-user state). Idempotent.
  _i3.Future<void> archiveRoom({required int roomId}) =>
      caller.callServerEndpoint<void>(
        'messenger',
        'archiveRoom',
        {'roomId': roomId},
      );

  /// Restore из archive. Idempotent.
  _i3.Future<void> unarchiveRoom({required int roomId}) =>
      caller.callServerEndpoint<void>(
        'messenger',
        'unarchiveRoom',
        {'roomId': roomId},
      );

  /// **TASK75 §3**: «закрыть» support-чат у текущего оператора — скрыть до
  /// следующего сообщения заявителя (per-user, `dismissedUntilMessage`).
  /// Тикет/комната не закрываются; авто-возврат — на сообщение заявителя
  /// (`RoomService.resetSupportDismissForRequesterMessage`). Idempotent.
  _i3.Future<void> dismissRoom({required int roomId}) =>
      caller.callServerEndpoint<void>(
        'messenger',
        'dismissRoom',
        {'roomId': roomId},
      );

  /// Покинуть комнату. Для direct chat — после leave + новый
  /// `createDirect(peer)` создаст fresh Matrix room (Telegram-style;
  /// см. `RoomService.leaveRoom` doc).
  ///
  /// Other participants получают `MessengerEventType.membershipLeft`
  /// через свой `userEventStream` (Matrix sync пропагирует
  /// `m.room.member` event). Cross-device: alice's other devices
  /// тоже получают.
  _i3.Future<void> leaveRoom({required int roomId}) =>
      caller.callServerEndpoint<void>(
        'messenger',
        'leaveRoom',
        {'roomId': roomId},
      );

  /// Список products в которых у viewer есть >=1 RoomMembership.
  /// Используется в SDK ProductFilter dropdown (standalone mode).
  /// Не фильтруется по `archived` — dropdown включает все products
  /// независимо от текущего archive-tab.
  _i3.Future<List<_i59.Product>> getAvailableProducts() =>
      caller.callServerEndpoint<List<_i59.Product>>(
        'messenger',
        'getAvailableProducts',
        {},
      );

  /// Записать presence-состояние ТЕКУЩЕГО пользователя в Redis-кэш с
  /// TTL. SDK вызывает при открытии ChatScreen, при сворачивании app-а,
  /// и каждые ~25 сек как heartbeat. Используется
  /// `PushRoutingService` (TASK20) для foreground suppression.
  _i3.Future<void> setPresence({
    int? currentRoomId,
    required bool foreground,
  }) => caller.callServerEndpoint<void>(
    'messenger',
    'setPresence',
    {
      'currentRoomId': currentRoomId,
      'foreground': foreground,
    },
  );

  /// Прочитать presence-состояние любого пользователя в том же tenant-е,
  /// что и caller (читать чужой presence — нормальный сценарий: UI
  /// «онлайн ли собеседник»). Возвращает `null`:
  ///   * если TTL истёк (клиент офлайн);
  ///   * если запись не существует (юзер никогда не пинговался);
  ///   * **если target-юзер в другом tenant-е** — silent null,
  ///     не отличимый от offline. Это anti-enumeration: иначе атакующий
  ///     по разнице ответа `null` (нет) vs typed-exception (есть, но
  ///     в другом tenant) скрейпил бы id-пространство. См. ревью
  ///     7d545ff п.2.
  _i3.Future<_i60.PresenceState?> getPresence({required int messengerUserId}) =>
      caller.callServerEndpoint<_i60.PresenceState?>(
        'messenger',
        'getPresence',
        {'messengerUserId': messengerUserId},
      );

  /// **TASK20-Phase2 Chunk 4**: получить notification preferences
  /// текущего user-а. Используется SDK [NsgMessengerSettings] для
  /// initial load + после `setNotificationSettings` round-trip.
  /// Default-ы из `MessengerUser` schema (`showMessagePreview=true`).
  _i3.Future<_i61.NotificationSettings> getNotificationSettings() =>
      caller.callServerEndpoint<_i61.NotificationSettings>(
        'messenger',
        'getNotificationSettings',
        {},
      );

  /// **TASK61 «Проверить пуш»**: ставит тестовый пуш ТЕКУЩЕМУ пользователю
  /// на все его устройства с задержкой (10с — чтобы успеть свернуть/закрыть
  /// приложение и проверить доставку в обоих состояниях). Возвращает
  /// [PushTestResult] сразу: сколько устройств и через каких провайдеров
  /// (`fcm`/`rustore`/...) придёт пуш — клиент это показывает пользователю.
  ///
  /// Сам пуш доставляет [PushTestFutureCall] (обходит фильтры
  /// `PushRoutingService`: тест шлём себе же, mute/foreground подавлять не
  /// нужно). Если у пользователя нет push-устройств (нет токена / desktop /
  /// web) — `deviceCount == 0`, FutureCall не планируется.
  _i3.Future<_i62.PushTestResult> testPush() =>
      caller.callServerEndpoint<_i62.PushTestResult>(
        'messenger',
        'testPush',
        {},
      );

  /// **TASK20-Phase2 Chunk 4**: обновить notification preferences.
  /// `showMessagePreview` — required (snapshot semantics).
  /// **B11**: `sendReadReceipts` nullable — `null` от старого клиента =
  /// «не менять» (оставляем текущее значение колонки).
  /// **Settings**: `discoverable` nullable — те же семантики (приватность
  /// «можно ли найти в поиске»).
  _i3.Future<void> setNotificationSettings({
    required bool showMessagePreview,
    bool? sendReadReceipts,
    bool? discoverable,
    String? whoCanMessageMe,
    bool? showCardsOnCall,
    bool? presenceHidden,
  }) => caller.callServerEndpoint<void>(
    'messenger',
    'setNotificationSettings',
    {
      'showMessagePreview': showMessagePreview,
      'sendReadReceipts': sendReadReceipts,
      'discoverable': discoverable,
      'whoCanMessageMe': whoCanMessageMe,
      'showCardsOnCall': showCardsOnCall,
      'presenceHidden': presenceHidden,
    },
  );

  /// **TASK64**: все языковые версии своего профиля (для редактора).
  _i3.Future<List<_i63.ProfileTranslation>> listMyProfileTranslations() =>
      caller.callServerEndpoint<List<_i63.ProfileTranslation>>(
        'messenger',
        'listMyProfileTranslations',
        {},
      );

  /// **TASK64**: записать языковую версию профиля. null = не менять,
  /// пустая строка = очистить; полностью пустая версия удаляется
  /// (возврат null).
  _i3.Future<_i63.ProfileTranslation?> setProfileTranslation({
    required String locale,
    String? displayName,
    String? about,
    String? jobTitle,
    String? company,
  }) => caller.callServerEndpoint<_i63.ProfileTranslation?>(
    'messenger',
    'setProfileTranslation',
    {
      'locale': locale,
      'displayName': displayName,
      'about': about,
      'jobTitle': jobTitle,
      'company': company,
    },
  );

  /// **TASK64**: пометить язык профилем по умолчанию — перевод
  /// копируется в базовые поля (их видят legacy-пути), прежняя база
  /// сохраняется переводом старой локали. Best-effort синк имени в
  /// Matrix-профиль.
  _i3.Future<void> setDefaultProfileLocale({required String locale}) =>
      caller.callServerEndpoint<void>(
        'messenger',
        'setDefaultProfileLocale',
        {'locale': locale},
      );

  /// **TASK64**: локаль интерфейса смотрящего — SDK сообщает на старте;
  /// по ней сервер выбирает языковые версии чужих профилей.
  _i3.Future<void> setUiLocale({required String locale}) =>
      caller.callServerEndpoint<void>(
        'messenger',
        'setUiLocale',
        {'locale': locale},
      );

  /// **Settings (Профиль и Настройки)**: сменить отображаемое имя.
  /// Обновляет `MessengerUser.displayName` (то, что видно в чатах) +
  /// best-effort синк в Matrix-профиль + зеркалит в `EmailAccount.
  /// displayName` (для multi-account roster и будущих логинов). Валидация
  /// 1..50 символов после trim.
  _i3.Future<void> setDisplayName({required String displayName}) =>
      caller.callServerEndpoint<void>(
        'messenger',
        'setDisplayName',
        {'displayName': displayName},
      );

  /// **Временный maintenance-endpoint**: backfill серверного
  /// `message_index` из существующей Matrix-истории всех active-комнат.
  /// Главный агент вызывает это ОДИН раз после деплоя, чтобы поиск нашёл
  /// уже отправленные (до включения индексации) сообщения.
  ///
  /// Возвращает map `matrixRoomId → indexed count` (`-1` = ошибка для
  /// этой комнаты, `0` = нет member-а с Matrix-токеном / пусто).
  ///
  /// **Guard**: caller должен (а) быть аутентифицирован messenger-токеном
  /// И (б) его email — в allowlist-е `SEARCH_INDEX_ADMIN_EMAILS`
  /// (comma-separated env). Если env пуст — endpoint disabled (бросает
  /// [MessengerNotAuthenticatedException]), чтобы случайно не открыть
  /// дорогую операцию всем. Защита намеренно простая — это temporary
  /// maintenance, не постоянная админка.
  _i3.Future<Map<String, int>> adminBackfillSearchIndex() =>
      caller.callServerEndpoint<Map<String, int>>(
        'messenger',
        'adminBackfillSearchIndex',
        {},
      );
}

/// **Issue #49 (открытая платформа ботов)**: self-service «Мои боты» для
/// ОБЫЧНОГО пользователя — в отличие от [BotAdminEndpoint]
/// (BOT_ADMIN_EMAILS, все боты tenant-а) здесь нет админ-гейта, а скоуп —
/// только СВОИ боты, по совпадению email caller-а с `bots.ownerEmail`.
///
/// Авторизация каждого метода:
///   1. messenger-токен ([requireMessengerUserId]);
///   2. email caller-а через [AdminEmailGate.emailOf] (IdentityMapping →
///      EmailAccount; у бота/ghost-а email-а нет → отказ: бот не может
///      владеть ботами);
///   3. для методов с botId — `bot.ownerEmail == email` (case-insensitive).
///      Чужой/несуществующий botId → ОДИН И ТОТ ЖЕ
///      [BotNotFoundException] (anti-enumeration: перебором id нельзя
///      выяснить, какие боты существуют).
///
/// Создание ограничено [BotService.maxBotsPerOwner] (превышение —
/// типизированный [BotLimitExceededException] с человекочитаемым лимитом);
/// админ-путь лимита не имеет. `accessToken` наружу отдаётся только в
/// ответах [create]/[rotateToken] — как в админке.
/// {@category Endpoint}
class EndpointMyBots extends _i2.EndpointRef {
  EndpointMyBots(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'myBots';

  /// Свои боты. `accessToken` зануляется — credential виден один раз, в
  /// ответе [create]/[rotateToken] (то же правило, что в админке: иначе
  /// токены уезжали бы на клиента при каждом открытии списка).
  _i3.Future<List<_i7.Bot>> list() => caller.callServerEndpoint<List<_i7.Bot>>(
    'myBots',
    'list',
    {},
  );

  /// Создать своего бота. `ownerEmail` НЕ параметр — всегда email caller-а
  /// (иначе можно было бы вешать ботов на чужой лимит и отдавать чужому
  /// владельцу управление). Tenant — tenant caller-а, product-привязки нет.
  ///
  /// [capabilities] — CSV грантов (`send_messages,manage_room`);
  /// [discoverable] — виден ли бот в поиске (дефолт false: публичность —
  /// осознанный выбор).
  ///
  /// Возвращаемый [Bot] несёт `accessToken` — показать владельцу ОДИН раз.
  _i3.Future<_i7.Bot> create({
    required String name,
    required String capabilities,
    required bool discoverable,
  }) => caller.callServerEndpoint<_i7.Bot>(
    'myBots',
    'create',
    {
      'name': name,
      'capabilities': capabilities,
      'discoverable': discoverable,
    },
  );

  /// Ротация credential-а своего бота: новый `accessToken`, прежние
  /// отозваны немедленно. Ответ несёт новый токен — показать ОДИН раз.
  _i3.Future<_i7.Bot> rotateToken({required int botId}) =>
      caller.callServerEndpoint<_i7.Bot>(
        'myBots',
        'rotateToken',
        {'botId': botId},
      );

  /// Kill-switch своего бота.
  _i3.Future<_i7.Bot> setEnabled({
    required int botId,
    required bool enabled,
  }) => caller.callServerEndpoint<_i7.Bot>(
    'myBots',
    'setEnabled',
    {
      'botId': botId,
      'enabled': enabled,
    },
  );

  /// Видимость своего бота в поиске (`searchUsers`). Выключено — бота
  /// нельзя найти и позвать в чужую комнату; уже созданные membership-ы
  /// не трогаются (отзыв — [removeFromRoom]).
  _i3.Future<_i7.Bot> setDiscoverable({
    required int botId,
    required bool discoverable,
  }) => caller.callServerEndpoint<_i7.Bot>(
    'myBots',
    'setDiscoverable',
    {
      'botId': botId,
      'discoverable': discoverable,
    },
  );

  /// Комнаты своего бота — владелец видит, куда бота позвали (добавление
  /// discoverable-бота свободно, контроль постфактум: этот список +
  /// [removeFromRoom]).
  _i3.Future<List<_i9.RoomSummary>> listRooms({required int botId}) =>
      caller.callServerEndpoint<List<_i9.RoomSummary>>(
        'myBots',
        'listRooms',
        {'botId': botId},
      );

  /// Отозвать своего бота из комнаты [roomId]: Matrix-leave от имени бота
  /// + удаление membership + аудит. Идемпотентно.
  _i3.Future<void> removeFromRoom({
    required int botId,
    required int roomId,
  }) => caller.callServerEndpoint<void>(
    'myBots',
    'removeFromRoom',
    {
      'botId': botId,
      'roomId': roomId,
    },
  );

  /// Журнал своего бота, свежие сверху: создание, ротации, вкл/выкл,
  /// видимость, добавления/отзывы из комнат, `capability_denied`. Тот же
  /// формат, что в админке ([BotAdminEndpoint.listAuditEvents]), — SDK
  /// переиспользует один UI аудита.
  _i3.Future<List<_i8.BotAuditEvent>> listAuditEvents({
    required int botId,
    required int limit,
  }) => caller.callServerEndpoint<List<_i8.BotAuditEvent>>(
    'myBots',
    'listAuditEvents',
    {
      'botId': botId,
      'limit': limit,
    },
  );
}

/// **TASK72**: S2S-endpoint приёма продуктовых уведомлений. Продукт-
/// сервер (за NAT, без публичного TLS) делает один вызов [send] —
/// nsg_connect резолвит устройства адресатов по своему реестру токенов и
/// доставляет через свою push-инфру.
///
/// Авторизация — per-tenant serviceSecret (тот же TASK78-секрет, которым
/// продукт авторизует выдачу connect-токенов; sha256-хэш в
/// `Tenant.connectServiceSecretHash`, сравнение constant-time + grace
/// ротации). Секрет — в ТЕЛЕ запроса (Serverpod RPC = POST), в query и в
/// логи не попадает. [unauthenticatedClientCall]: вызывающий — продукт-
/// сервер, messenger-сессии у него нет (образец [ConnectTokenEndpoint]).
///
/// **collapseKey/priority/ttl** приняты в контракт (стабильность API), но
/// на этой итерации в FCM НЕ пробрасываются: `PushPayload` их не несёт, а
/// проброс требует расширения payload + адаптеров (вне скоупа — «не трогай
/// воркер/адаптеры»). Follow-up. Пока кладём collapseKey/ttl в лог для
/// диагностики и игнорируем на доставке.
/// {@category Endpoint}
class EndpointProductNotification extends _i2.EndpointRef {
  EndpointProductNotification(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'productNotification';

  /// Разослать одно продуктовое уведомление списку адресатов (batch).
  ///
  /// Отказы: [InvalidTokenException] `reason='send_denied'` на любую
  /// проблему авторизации (anti-enumeration, причина — в server-логе);
  /// [ProductNotFoundException] — только после успешной проверки секрета;
  /// [RateLimitExceededException] — флуд/серия неверных секретов;
  /// [InvalidNotificationException] `reason=<validation>` — кривой вход
  /// (пустой список, пустой контент, слишком длинно). Валидация — до
  /// любых обращений в БД, продукту отдаём внятную причину (не секрет).
  _i3.Future<_i64.ProductNotificationSendResult> send({
    required String tenantExternalKey,
    required String productExternalKey,
    required String serviceSecret,
    required List<String> externalUserIds,
    required String title,
    required String body,
    required String idempotencyKey,
    Map<String, String>? data,
    String? collapseKey,
    String? priority,
    int? ttlSeconds,
  }) => caller.callServerEndpoint<_i64.ProductNotificationSendResult>(
    'productNotification',
    'send',
    {
      'tenantExternalKey': tenantExternalKey,
      'productExternalKey': productExternalKey,
      'serviceSecret': serviceSecret,
      'externalUserIds': externalUserIds,
      'title': title,
      'body': body,
      'idempotencyKey': idempotencyKey,
      'data': data,
      'collapseKey': collapseKey,
      'priority': priority,
      'ttlSeconds': ttlSeconds,
    },
    authenticated: false,
  );
}

/// **TASK60 (Connect Pulse)**: управление мониторингом — папки, мониторы,
/// правила алертов, инциденты (ack), realtime-стрим статусов.
///
/// Гейт — env `PULSE_ADMIN_EMAILS` (CSV; конкретные адреса — в конфиге
/// прод-окружения, в код не тащить: докстринги уезжают в generated
/// client, который уходит наружу). Anti-enumeration: отказ = тот же
/// [MessengerNotAuthenticatedException]. Роль-модель — при продуктализации.
/// {@category Endpoint}
class EndpointPulse extends _i2.EndpointRef {
  EndpointPulse(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'pulse';

  /// Живые события дашборда: переходы статусов, инциденты.
  /// Дашборд перечитывает узел из `event.monitor` без refetch дерева.
  _i3.Stream<_i65.PulseEvent> statusStream() =>
      caller.callStreamingServerEndpoint<
        _i3.Stream<_i65.PulseEvent>,
        _i65.PulseEvent
      >(
        'pulse',
        'statusStream',
        {},
        {},
      );

  _i3.Future<List<_i66.PulseFolder>> listFolders() =>
      caller.callServerEndpoint<List<_i66.PulseFolder>>(
        'pulse',
        'listFolders',
        {},
      );

  _i3.Future<_i66.PulseFolder> createFolder({
    required String name,
    int? parentId,
  }) => caller.callServerEndpoint<_i66.PulseFolder>(
    'pulse',
    'createFolder',
    {
      'name': name,
      'parentId': parentId,
    },
  );

  _i3.Future<_i66.PulseFolder> renameFolder({
    required int id,
    required String name,
  }) => caller.callServerEndpoint<_i66.PulseFolder>(
    'pulse',
    'renameFolder',
    {
      'id': id,
      'name': name,
    },
  );

  /// Удаление только пустой папки (без подпапок/мониторов) — иначе
  /// ArgumentError. Осознанное MVP-упрощение вместо каскада/репарентинга.
  _i3.Future<void> deleteFolder({required int id}) =>
      caller.callServerEndpoint<void>(
        'pulse',
        'deleteFolder',
        {'id': id},
      );

  _i3.Future<List<_i67.PulseMonitor>> listMonitors() =>
      caller.callServerEndpoint<List<_i67.PulseMonitor>>(
        'pulse',
        'listMonitors',
        {},
      );

  /// Создать монитор → beat-токен + готовый URL (показать один раз).
  _i3.Future<_i68.PulseMonitorCreated> createMonitor({
    required String name,
    int? folderId,
    required int periodSeconds,
    required int graceSeconds,
  }) => caller.callServerEndpoint<_i68.PulseMonitorCreated>(
    'pulse',
    'createMonitor',
    {
      'name': name,
      'folderId': folderId,
      'periodSeconds': periodSeconds,
      'graceSeconds': graceSeconds,
    },
  );

  /// Ротация beat-токена (тот же монитор; старый токен мёртв немедленно).
  _i3.Future<_i68.PulseMonitorCreated> rotateToken({required int id}) =>
      caller.callServerEndpoint<_i68.PulseMonitorCreated>(
        'pulse',
        'rotateToken',
        {'id': id},
      );

  /// Пауза (обслуживание/деплой): beat → 403, свипер/алерты пропускают.
  _i3.Future<_i67.PulseMonitor> setPaused({
    required int id,
    required bool paused,
  }) => caller.callServerEndpoint<_i67.PulseMonitor>(
    'pulse',
    'setPaused',
    {
      'id': id,
      'paused': paused,
    },
  );

  _i3.Future<void> deleteMonitor({required int id}) =>
      caller.callServerEndpoint<void>(
        'pulse',
        'deleteMonitor',
        {'id': id},
      );

  _i3.Future<List<_i69.PulseAlertRule>> listRules() =>
      caller.callServerEndpoint<List<_i69.PulseAlertRule>>(
        'pulse',
        'listRules',
        {},
      );

  /// Создать правило: ровно один scope (папка ИЛИ монитор). Заводит/находит
  /// тенантного Pulse-бота и добавляет его в комнату-цель.
  _i3.Future<_i69.PulseAlertRule> createRule({
    int? scopeFolderId,
    int? scopeMonitorId,
    required int roomId,
    required String minSeverity,
    int? escalateAfterMinutes,
    String? level1UserIds,
    int? escalate2AfterMinutes,
    String? level2UserIds,
  }) => caller.callServerEndpoint<_i69.PulseAlertRule>(
    'pulse',
    'createRule',
    {
      'scopeFolderId': scopeFolderId,
      'scopeMonitorId': scopeMonitorId,
      'roomId': roomId,
      'minSeverity': minSeverity,
      'escalateAfterMinutes': escalateAfterMinutes,
      'level1UserIds': level1UserIds,
      'escalate2AfterMinutes': escalate2AfterMinutes,
      'level2UserIds': level2UserIds,
    },
  );

  _i3.Future<void> deleteRule({required int id}) =>
      caller.callServerEndpoint<void>(
        'pulse',
        'deleteRule',
        {'id': id},
      );

  _i3.Future<List<_i70.PulseIncident>> listIncidents({
    required int monitorId,
    required int limit,
  }) => caller.callServerEndpoint<List<_i70.PulseIncident>>(
    'pulse',
    'listIncidents',
    {
      'monitorId': monitorId,
      'limit': limit,
    },
  );

  /// «Взять в работу» — останавливает эскалацию.
  _i3.Future<_i70.PulseIncident> ackIncident({required int incidentId}) =>
      caller.callServerEndpoint<_i70.PulseIncident>(
        'pulse',
        'ackIncident',
        {'incidentId': incidentId},
      );
}

/// **TASK38**: admin-only управление per-tenant конфигом интеграции с
/// таск-трекером (`create task from message`). КАЖДЫЙ метод gate-ится через
/// [requireMessengerUserId] + email caller-а в allowlist-е env
/// `TASK_ADMIN_EMAILS` (CSV). Unauthorized → [MessengerNotAuthenticatedException]
/// (anti-enumeration). Зеркалит `AdminWebhookEndpoint._gate`.
///
/// Резолв tenant/product — по externalKey (`nsg` / `chatista`). URL
/// валидируется [WebhookUrlValidator] (SSRF-гард) на upsert.
/// {@category Endpoint}
class EndpointTaskAdmin extends _i2.EndpointRef {
  EndpointTaskAdmin(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'taskAdmin';

  /// Upsert конфига интеграции по (tenantId, productId). [adapterType] —
  /// `generic_webhook` (TASK38, дефолт) или `github` (**TASK57**). Валидация
  /// `url` зависит от типа: webhook — SSRF-гард (`WebhookUrlValidator`);
  /// github — формат `owner/repo`. Секрет генерится если не задан (для github
  /// не используется — токен берётся из env `GITHUB_TOKEN`).
  _i3.Future<_i71.TaskManagerConfig> setTaskManagerConfig({
    required String tenantExternalKey,
    String? productExternalKey,
    required String url,
    String? adapterType,
    String? secret,
    required bool enabled,
  }) => caller.callServerEndpoint<_i71.TaskManagerConfig>(
    'taskAdmin',
    'setTaskManagerConfig',
    {
      'tenantExternalKey': tenantExternalKey,
      'productExternalKey': productExternalKey,
      'url': url,
      'adapterType': adapterType,
      'secret': secret,
      'enabled': enabled,
    },
  );

  /// Возвращает конфиг для (tenantId, productId) или `null`.
  _i3.Future<_i71.TaskManagerConfig?> getTaskManagerConfig({
    required String tenantExternalKey,
    String? productExternalKey,
  }) => caller.callServerEndpoint<_i71.TaskManagerConfig?>(
    'taskAdmin',
    'getTaskManagerConfig',
    {
      'tenantExternalKey': tenantExternalKey,
      'productExternalKey': productExternalKey,
    },
  );
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _i2.EndpointRef {
  EndpointGreeting(_i2.EndpointCaller caller) : super(caller);

  @override
  String get name => 'greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _i3.Future<_i72.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i72.Greeting>(
        'greeting',
        'hello',
        {'name': name},
      );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _i1.Caller(client);
    serverpod_auth_core = _i4.Caller(client);
  }

  late final _i1.Caller serverpod_auth_idp;

  late final _i4.Caller serverpod_auth_core;
}

class Client extends _i2.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i2.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i2.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
         host,
         _i73.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    emailIdp = EndpointEmailIdp(this);
    jwtRefresh = EndpointJwtRefresh(this);
    adminWebhook = EndpointAdminWebhook(this);
    botAdmin = EndpointBotAdmin(this);
    botIntegration = EndpointBotIntegration(this);
    connectTenantAdmin = EndpointConnectTenantAdmin(this);
    connectToken = EndpointConnectToken(this);
    emailAuth = EndpointEmailAuth(this);
    incomingWebhook = EndpointIncomingWebhook(this);
    messenger = EndpointMessenger(this);
    myBots = EndpointMyBots(this);
    productNotification = EndpointProductNotification(this);
    pulse = EndpointPulse(this);
    taskAdmin = EndpointTaskAdmin(this);
    greeting = EndpointGreeting(this);
    modules = Modules(this);
  }

  late final EndpointEmailIdp emailIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointAdminWebhook adminWebhook;

  late final EndpointBotAdmin botAdmin;

  late final EndpointBotIntegration botIntegration;

  late final EndpointConnectTenantAdmin connectTenantAdmin;

  late final EndpointConnectToken connectToken;

  late final EndpointEmailAuth emailAuth;

  late final EndpointIncomingWebhook incomingWebhook;

  late final EndpointMessenger messenger;

  late final EndpointMyBots myBots;

  late final EndpointProductNotification productNotification;

  late final EndpointPulse pulse;

  late final EndpointTaskAdmin taskAdmin;

  late final EndpointGreeting greeting;

  late final Modules modules;

  @override
  Map<String, _i2.EndpointRef> get endpointRefLookup => {
    'emailIdp': emailIdp,
    'jwtRefresh': jwtRefresh,
    'adminWebhook': adminWebhook,
    'botAdmin': botAdmin,
    'botIntegration': botIntegration,
    'connectTenantAdmin': connectTenantAdmin,
    'connectToken': connectToken,
    'emailAuth': emailAuth,
    'incomingWebhook': incomingWebhook,
    'messenger': messenger,
    'myBots': myBots,
    'productNotification': productNotification,
    'pulse': pulse,
    'taskAdmin': taskAdmin,
    'greeting': greeting,
  };

  @override
  Map<String, _i2.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
