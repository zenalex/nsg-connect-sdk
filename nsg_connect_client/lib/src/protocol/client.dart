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
import 'package:nsg_connect_client/src/protocol/messenger_auth_context.dart'
    as _i5;
import 'package:nsg_connect_client/src/protocol/messenger_session.dart' as _i6;
import 'package:nsg_connect_client/src/protocol/messenger_message.dart' as _i7;
import 'package:nsg_connect_client/src/protocol/attachment_ref.dart' as _i8;
import 'package:nsg_connect_client/src/protocol/messenger_event.dart' as _i9;
import 'package:nsg_connect_client/src/protocol/enums/room_member_role.dart'
    as _i10;
import 'package:nsg_connect_client/src/protocol/room_participant.dart' as _i11;
import 'dart:typed_data' as _i12;
import 'package:nsg_connect_client/src/protocol/attachment_bytes.dart' as _i13;
import 'package:nsg_connect_client/src/protocol/messenger_message_list_page.dart'
    as _i14;
import 'package:nsg_connect_client/src/protocol/device_registration.dart'
    as _i15;
import 'package:nsg_connect_client/src/protocol/enums/device_platform.dart'
    as _i16;
import 'package:nsg_connect_client/src/protocol/enums/push_service.dart'
    as _i17;
import 'package:nsg_connect_client/src/protocol/room_summary.dart' as _i18;
import 'package:nsg_connect_client/src/protocol/enums/room_state.dart' as _i19;
import 'package:nsg_connect_client/src/protocol/room_details.dart' as _i20;
import 'package:nsg_connect_client/src/protocol/enums/room_type.dart' as _i21;
import 'package:nsg_connect_client/src/protocol/product.dart' as _i22;
import 'package:nsg_connect_client/src/protocol/presence_state.dart' as _i23;
import 'package:nsg_connect_client/src/protocol/notification_settings.dart'
    as _i24;
import 'package:nsg_connect_client/src/protocol/greetings/greeting.dart'
    as _i25;
import 'protocol.dart' as _i26;

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
  ///   * email не существует в этом tenant-е (иначе `email_already_taken`).
  ///
  /// **Не верифицирует email by link** — Phase2 task. Все newly-signed-up
  /// аккаунты сразу могут логиниться.
  _i3.Future<_i5.MessengerAuthContext> signUp({
    required String email,
    required String password,
    String? displayName,
    required String tenantExternalKey,
    String? productExternalKey,
    String? deviceId,
  }) => caller.callServerEndpoint<_i5.MessengerAuthContext>(
    'emailAuth',
    'signUp',
    {
      'email': email,
      'password': password,
      'displayName': displayName,
      'tenantExternalKey': tenantExternalKey,
      'productExternalKey': productExternalKey,
      'deviceId': deviceId,
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
  _i3.Future<_i5.MessengerAuthContext> signIn({
    required String email,
    required String password,
    required String tenantExternalKey,
    String? productExternalKey,
    String? deviceId,
  }) => caller.callServerEndpoint<_i5.MessengerAuthContext>(
    'emailAuth',
    'signIn',
    {
      'email': email,
      'password': password,
      'tenantExternalKey': tenantExternalKey,
      'productExternalKey': productExternalKey,
      'deviceId': deviceId,
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
  _i3.Future<_i5.MessengerAuthContext> verifyEmail({
    required String sessionToken,
    required String code,
    required String tenantExternalKey,
    String? productExternalKey,
    String? deviceId,
  }) => caller.callServerEndpoint<_i5.MessengerAuthContext>(
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
  _i3.Future<_i6.MessengerSession> session(_i5.MessengerAuthContext ctx) =>
      caller.callServerEndpoint<_i6.MessengerSession>(
        'messenger',
        'session',
        {'ctx': ctx},
        authenticated: false,
      );

  /// Refresh сессии: принимает тот же `MessengerAuthContext`, что был
  /// отдан в `session()`, проверяет его адаптером, выдаёт **новый**
  /// `sessionToken` для того же `messengerUserId`. Старый токен
  /// одновременно отзывается (revokedAt) — после refresh клиент должен
  /// использовать только новый.
  ///
  /// Семантика: повторный вход того же external user-а под идентичным
  /// контекстом → тот же `messengerUserId`. Это критично для invariant-а
  /// «один external user = одна messenger-личность» (см. TASK04, §6 ТЗ).
  ///
  /// **[unauthenticatedClientCall]**: аналогично [session], нужно чтобы
  /// клиентский mutex-refresher не зацикливал refresh → authHeader → refresh.
  _i3.Future<_i6.MessengerSession> refresh(_i5.MessengerAuthContext ctx) =>
      caller.callServerEndpoint<_i6.MessengerSession>(
        'messenger',
        'refresh',
        {'ctx': ctx},
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
  /// hashing-at-rest) и владелец может одним вызовом `refresh` отозвать
  /// все свои предыдущие токены.
  _i3.Future<void> revoke({required String sessionToken}) =>
      caller.callServerEndpoint<void>(
        'messenger',
        'revoke',
        {'sessionToken': sessionToken},
      );

  /// Отправить сообщение в комнату от лица текущего authenticated юзера.
  ///
  /// `attachment` (TASK19) — опциональная media-ссылка из предшествующего
  /// `uploadAttachment`. Если задана, server переопределяет `msgtype`
  /// на `m.image`/`m.video`/`m.file` per `attachment.mimeType` и кладёт
  /// `info` block в Matrix content (mxc url, dimensions, size).
  _i3.Future<_i7.MessengerMessage> sendMessage({
    required int roomId,
    required String body,
    required String msgType,
    String? clientTxnId,
    String? threadId,
    String? replyToMatrixEventId,
    _i8.AttachmentRef? attachment,
    List<int>? mentionedMessengerUserIds,
  }) => caller.callServerEndpoint<_i7.MessengerMessage>(
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
    },
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
  _i3.Future<_i7.MessengerMessage> editMessage({
    required int roomId,
    required String matrixEventId,
    required String newBody,
    List<int>? mentionedMessengerUserIds,
  }) => caller.callServerEndpoint<_i7.MessengerMessage>(
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

  /// **Reactions history (phase 2)**: для списка message `eventIds`
  /// возвращает существующие реакции как `reactionChanged`-add
  /// `MessengerEvent`-ы (тот же shape что realtime). SDK скармливает их
  /// в aggregation-путь после `listMessages`, чтобы реакции были видны
  /// сразу при открытии чата. Пустой `eventIds` → пустой list.
  _i3.Future<List<_i9.MessengerEvent>> listReactions({
    required int roomId,
    required List<String> eventIds,
  }) => caller.callServerEndpoint<List<_i9.MessengerEvent>>(
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
  _i3.Future<List<_i9.MessengerEvent>> listReadReceipts({
    required int roomId,
  }) => caller.callServerEndpoint<List<_i9.MessengerEvent>>(
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
    required _i10.RoomMemberRole newRole,
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
  _i3.Future<List<_i11.RoomParticipant>> listBannedUsers({
    required int roomId,
  }) => caller.callServerEndpoint<List<_i11.RoomParticipant>>(
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
  _i3.Future<_i8.AttachmentRef> uploadAttachment({
    required _i12.ByteData bytes,
    required String mimeType,
    required String originalFilename,
  }) => caller.callServerEndpoint<_i8.AttachmentRef>(
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
    required _i12.ByteData bytes,
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
    required _i12.ByteData bytes,
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
  _i3.Future<_i13.AttachmentBytes> downloadAttachment({
    required String mxcUrl,
  }) => caller.callServerEndpoint<_i13.AttachmentBytes>(
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
  _i3.Future<_i13.AttachmentBytes> downloadAttachmentThumbnail({
    required String mxcUrl,
    int? width,
    int? height,
  }) => caller.callServerEndpoint<_i13.AttachmentBytes>(
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
  _i3.Future<_i14.MessengerMessageListPage> listMessages({
    required int roomId,
    String? fromToken,
    required int limit,
  }) => caller.callServerEndpoint<_i14.MessengerMessageListPage>(
    'messenger',
    'listMessages',
    {
      'roomId': roomId,
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
  _i3.Future<List<_i7.MessengerMessage>> searchMessages({
    required int roomId,
    required String query,
    required int limit,
  }) => caller.callServerEndpoint<List<_i7.MessengerMessage>>(
    'messenger',
    'searchMessages',
    {
      'roomId': roomId,
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
  _i3.Future<_i15.DeviceRegistration> registerDevice({
    required _i16.DevicePlatform platform,
    required String pushToken,
    required _i17.PushService pushService,
    required String locale,
    required String appVersion,
    String? deviceModel,
    String? productExternalKey,
  }) => caller.callServerEndpoint<_i15.DeviceRegistration>(
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

  /// Главный realtime-стрим текущего пользователя — пушит
  /// [MessengerEvent]-ы для всех его комнат. Под капотом — запуск
  /// `/sync` worker-а в [MatrixSyncDispatcher] и подписка на
  /// Redis-канал `messenger:user:<id>:events` через MessageBus.
  ///
  /// Реализация — `async*`, чтобы `requireMessengerUserId` бросил
  /// `MessengerNotAuthenticatedException` ДО первого `yield`. Serverpod
  /// доставит exception клиенту через stream-error канала, и SDK
  /// обработает 401-retry.
  _i3.Stream<_i9.MessengerEvent> userEventStream() =>
      caller.callStreamingServerEndpoint<
        _i3.Stream<_i9.MessengerEvent>,
        _i9.MessengerEvent
      >(
        'messenger',
        'userEventStream',
        {},
        {},
      );

  /// Список комнат, в которых состоит текущий юзер. Только из локальной
  /// БД (sync-loop держит lastMessageAt/Body в актуальном состоянии).
  /// Параметры `state` / `search` / `includeArchived` заложены в
  /// сигнатуре, но фильтрация — TASK42 (UX); сейчас работают только
  /// `productId` + `cursor`.
  _i3.Future<List<_i18.RoomSummary>> listRooms({
    int? productId,
    _i19.RoomState? state,
    String? search,
    bool? includeArchived,
    required int limit,
    String? cursor,
  }) => caller.callServerEndpoint<List<_i18.RoomSummary>>(
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

  /// Подробности конкретной комнаты + первые 30 участников + viewer-роль.
  /// Если caller не состоит в membership — `RoomUnavailableException`
  /// (anti-enumeration).
  _i3.Future<_i20.RoomDetails> getRoom({required int roomId}) =>
      caller.callServerEndpoint<_i20.RoomDetails>(
        'messenger',
        'getRoom',
        {'roomId': roomId},
      );

  /// Идемпотентно создать direct chat caller↔peer. Заменяет старый
  /// `getOrCreateDirect`. Cross-tenant / non-existent peer →
  /// `PeerUnavailableException` (anti-enumeration).
  _i3.Future<_i20.RoomDetails> createDirect({
    required int peerMessengerUserId,
  }) => caller.callServerEndpoint<_i20.RoomDetails>(
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
  _i3.Future<_i11.RoomParticipant> findUserByEmail({
    required String email,
    required String tenantExternalKey,
  }) => caller.callServerEndpoint<_i11.RoomParticipant>(
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
  _i3.Future<List<_i11.RoomParticipant>> listKnownContacts() =>
      caller.callServerEndpoint<List<_i11.RoomParticipant>>(
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
  _i3.Future<List<_i11.RoomParticipant>> searchUsers({
    required String query,
    required int limit,
    required String tenantExternalKey,
  }) => caller.callServerEndpoint<List<_i11.RoomParticipant>>(
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
  _i3.Future<_i20.RoomDetails> createGroup({
    required String name,
    required List<int> memberMessengerUserIds,
    int? productId,
  }) => caller.callServerEndpoint<_i20.RoomDetails>(
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
  _i3.Future<_i20.RoomDetails> getOrCreateProductRoom({
    required String productExternalKey,
    required String entityType,
    required String entityId,
    required _i21.RoomType roomType,
  }) => caller.callServerEndpoint<_i20.RoomDetails>(
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
  _i3.Future<_i20.RoomDetails> openSupportChat({
    required String productExternalKey,
    required String contextId,
  }) => caller.callServerEndpoint<_i20.RoomDetails>(
    'messenger',
    'openSupportChat',
    {
      'productExternalKey': productExternalKey,
      'contextId': contextId,
    },
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
  _i3.Future<List<_i22.Product>> getAvailableProducts() =>
      caller.callServerEndpoint<List<_i22.Product>>(
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
  _i3.Future<_i23.PresenceState?> getPresence({required int messengerUserId}) =>
      caller.callServerEndpoint<_i23.PresenceState?>(
        'messenger',
        'getPresence',
        {'messengerUserId': messengerUserId},
      );

  /// **TASK20-Phase2 Chunk 4**: получить notification preferences
  /// текущего user-а. Используется SDK [NsgMessengerSettings] для
  /// initial load + после `setNotificationSettings` round-trip.
  /// Default-ы из `MessengerUser` schema (`showMessagePreview=true`).
  _i3.Future<_i24.NotificationSettings> getNotificationSettings() =>
      caller.callServerEndpoint<_i24.NotificationSettings>(
        'messenger',
        'getNotificationSettings',
        {},
      );

  /// **TASK20-Phase2 Chunk 4**: обновить notification preferences. Все
  /// поля required (snapshot semantics — caller передаёт полный desired
  /// state). На MVP — single bool, на Phase3 expansion DTO get-ит
  /// дополнительные поля.
  _i3.Future<void> setNotificationSettings({
    required bool showMessagePreview,
  }) => caller.callServerEndpoint<void>(
    'messenger',
    'setNotificationSettings',
    {'showMessagePreview': showMessagePreview},
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
  _i3.Future<_i25.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i25.Greeting>(
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
         _i26.Protocol(),
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
    emailAuth = EndpointEmailAuth(this);
    messenger = EndpointMessenger(this);
    greeting = EndpointGreeting(this);
    modules = Modules(this);
  }

  late final EndpointEmailIdp emailIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointEmailAuth emailAuth;

  late final EndpointMessenger messenger;

  late final EndpointGreeting greeting;

  late final Modules modules;

  @override
  Map<String, _i2.EndpointRef> get endpointRefLookup => {
    'emailIdp': emailIdp,
    'jwtRefresh': jwtRefresh,
    'emailAuth': emailAuth,
    'messenger': messenger,
    'greeting': greeting,
  };

  @override
  Map<String, _i2.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
