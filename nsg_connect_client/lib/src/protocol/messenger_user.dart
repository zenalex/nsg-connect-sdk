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
import 'package:serverpod_client/serverpod_client.dart' as _i1;

/// MessengerUser — внутренний пользователь NSG Connect, связанный с
/// Matrix-аккаунтом через matrixUserId (см. TASK07 для детерминированной
/// генерации localpart-а).
/// См. ТЗ §6.
abstract class MessengerUser implements _i1.SerializableModel {
  MessengerUser._({
    this.id,
    required this.tenantId,
    required this.matrixUserId,
    this.matrixAccessTokenEncrypted,
    this.displayName,
    this.avatarUrl,
    bool? showMessagePreview,
    bool? sendReadReceipts,
    bool? discoverable,
    required this.createdAt,
  }) : showMessagePreview = showMessagePreview ?? true,
       sendReadReceipts = sendReadReceipts ?? true,
       discoverable = discoverable ?? true;

  factory MessengerUser({
    int? id,
    required int tenantId,
    required String matrixUserId,
    String? matrixAccessTokenEncrypted,
    String? displayName,
    String? avatarUrl,
    bool? showMessagePreview,
    bool? sendReadReceipts,
    bool? discoverable,
    required DateTime createdAt,
  }) = _MessengerUserImpl;

  factory MessengerUser.fromJson(Map<String, dynamic> jsonSerialization) {
    return MessengerUser(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      matrixUserId: jsonSerialization['matrixUserId'] as String,
      matrixAccessTokenEncrypted:
          jsonSerialization['matrixAccessTokenEncrypted'] as String?,
      displayName: jsonSerialization['displayName'] as String?,
      avatarUrl: jsonSerialization['avatarUrl'] as String?,
      showMessagePreview: jsonSerialization['showMessagePreview'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['showMessagePreview'],
            ),
      sendReadReceipts: jsonSerialization['sendReadReceipts'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(
              jsonSerialization['sendReadReceipts'],
            ),
      discoverable: jsonSerialization['discoverable'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['discoverable']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  int tenantId;

  /// Полный matrix user id вида `@nsg-<tenant>-<hash>:<server>`.
  String matrixUserId;

  /// AES-GCM-шифрованный access_token Matrix-пользователя (TASK07 решает
  /// финальную стратегию: токен в БД vs Application Service).
  /// Хранится как base64 от nonce(12)||ct||tag(16).
  String? matrixAccessTokenEncrypted;

  String? displayName;

  String? avatarUrl;

  /// **TASK20-Phase2 Chunk 4**: показывать содержимое сообщения в push
  /// notification preview. `true` (default) → title/body содержат
  /// sender displayName + body excerpt. `false` → generic «Новое
  /// сообщение в <room>» без disclosure of message content (privacy
  /// preference; useful when device shared / on lock-screen / employer-
  /// managed phone).
  ///
  /// **Single-column convention**: при добавлении большего числа
  /// notification settings (DnD hours / sound / vibrate-only) — extract
  /// в `UserNotificationSettings` table в Phase3. Сейчас 1 bool, 0
  /// overhead, отдельная таблица — overengineering.
  bool showMessagePreview;

  /// **B11**: отправлять ли read-receipts (m.read) другим участникам.
  /// false = «инкогнито-чтение»: markRead шлёт m.read.private (свой unread
  /// чистится, но peer НЕ видит ✓✓). default=true (как было).
  bool sendReadReceipts;

  /// **Settings (Профиль и Настройки)**: discoverable в поиске. `true`
  /// (default) → пользователь находится через `searchUsers`/`findUserByEmail`
  /// другими. `false` → скрыт от поиска (кроме self-lookup — свой профиль
  /// по своему email всегда виден). Privacy-toggle: «не дать незнакомцам
  /// найти меня по имени/@username/email». Default true = backward-compat
  /// (существующие строки остаются находимыми).
  bool discoverable;

  DateTime createdAt;

  /// Returns a shallow copy of this [MessengerUser]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  MessengerUser copyWith({
    int? id,
    int? tenantId,
    String? matrixUserId,
    String? matrixAccessTokenEncrypted,
    String? displayName,
    String? avatarUrl,
    bool? showMessagePreview,
    bool? sendReadReceipts,
    bool? discoverable,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'MessengerUser',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      'matrixUserId': matrixUserId,
      if (matrixAccessTokenEncrypted != null)
        'matrixAccessTokenEncrypted': matrixAccessTokenEncrypted,
      if (displayName != null) 'displayName': displayName,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'showMessagePreview': showMessagePreview,
      'sendReadReceipts': sendReadReceipts,
      'discoverable': discoverable,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _MessengerUserImpl extends MessengerUser {
  _MessengerUserImpl({
    int? id,
    required int tenantId,
    required String matrixUserId,
    String? matrixAccessTokenEncrypted,
    String? displayName,
    String? avatarUrl,
    bool? showMessagePreview,
    bool? sendReadReceipts,
    bool? discoverable,
    required DateTime createdAt,
  }) : super._(
         id: id,
         tenantId: tenantId,
         matrixUserId: matrixUserId,
         matrixAccessTokenEncrypted: matrixAccessTokenEncrypted,
         displayName: displayName,
         avatarUrl: avatarUrl,
         showMessagePreview: showMessagePreview,
         sendReadReceipts: sendReadReceipts,
         discoverable: discoverable,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [MessengerUser]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  MessengerUser copyWith({
    Object? id = _Undefined,
    int? tenantId,
    String? matrixUserId,
    Object? matrixAccessTokenEncrypted = _Undefined,
    Object? displayName = _Undefined,
    Object? avatarUrl = _Undefined,
    bool? showMessagePreview,
    bool? sendReadReceipts,
    bool? discoverable,
    DateTime? createdAt,
  }) {
    return MessengerUser(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      matrixUserId: matrixUserId ?? this.matrixUserId,
      matrixAccessTokenEncrypted: matrixAccessTokenEncrypted is String?
          ? matrixAccessTokenEncrypted
          : this.matrixAccessTokenEncrypted,
      displayName: displayName is String? ? displayName : this.displayName,
      avatarUrl: avatarUrl is String? ? avatarUrl : this.avatarUrl,
      showMessagePreview: showMessagePreview ?? this.showMessagePreview,
      sendReadReceipts: sendReadReceipts ?? this.sendReadReceipts,
      discoverable: discoverable ?? this.discoverable,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
