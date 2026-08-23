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

/// **issue #160**: одна запись журнала доставки — «что, когда, каким
/// способом, чем кончилось».
///
/// **Личных данных здесь нет и не будет**: ни имени, ни модели телефона,
/// ни токена. Продукт спрашивает про СВОЮ отправку, а не про человека.
/// Заголовок и текст уведомления тоже не возвращаем — они у продукта
/// свои, и хранить их ради ответа значило бы держать чужую переписку.
abstract class DeliveryJournalEntry implements _i1.SerializableModel {
  DeliveryJournalEntry._({
    required this.externalUserId,
    required this.status,
    this.reason,
    required this.deviceCount,
    required this.idempotencyKey,
    required this.createdAt,
  });

  factory DeliveryJournalEntry({
    required String externalUserId,
    required String status,
    String? reason,
    required int deviceCount,
    required String idempotencyKey,
    required DateTime createdAt,
  }) = _DeliveryJournalEntryImpl;

  factory DeliveryJournalEntry.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return DeliveryJournalEntry(
      externalUserId: jsonSerialization['externalUserId'] as String,
      status: jsonSerialization['status'] as String,
      reason: jsonSerialization['reason'] as String?,
      deviceCount: jsonSerialization['deviceCount'] as int,
      idempotencyKey: jsonSerialization['idempotencyKey'] as String,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  String externalUserId;

  /// `delivered` | `deduped` | `noDevices` | `unavailable` — как в ответе
  /// на отправку. `delivered` = «поставлено в очередь на устройства»;
  /// подтверждения от провайдера у нас нет и мы его не выдумываем.
  String status;

  /// Причина отказа, пусто у успеха.
  String? reason;

  /// На сколько устройств ушёл payload.
  int deviceCount;

  /// Ключ идемпотентности, как его прислал продукт, — по нему запись
  /// сопоставляется с его собственным журналом.
  String idempotencyKey;

  DateTime createdAt;

  /// Returns a shallow copy of this [DeliveryJournalEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  DeliveryJournalEntry copyWith({
    String? externalUserId,
    String? status,
    String? reason,
    int? deviceCount,
    String? idempotencyKey,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'DeliveryJournalEntry',
      'externalUserId': externalUserId,
      'status': status,
      if (reason != null) 'reason': reason,
      'deviceCount': deviceCount,
      'idempotencyKey': idempotencyKey,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _DeliveryJournalEntryImpl extends DeliveryJournalEntry {
  _DeliveryJournalEntryImpl({
    required String externalUserId,
    required String status,
    String? reason,
    required int deviceCount,
    required String idempotencyKey,
    required DateTime createdAt,
  }) : super._(
         externalUserId: externalUserId,
         status: status,
         reason: reason,
         deviceCount: deviceCount,
         idempotencyKey: idempotencyKey,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [DeliveryJournalEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  DeliveryJournalEntry copyWith({
    String? externalUserId,
    String? status,
    Object? reason = _Undefined,
    int? deviceCount,
    String? idempotencyKey,
    DateTime? createdAt,
  }) {
    return DeliveryJournalEntry(
      externalUserId: externalUserId ?? this.externalUserId,
      status: status ?? this.status,
      reason: reason is String? ? reason : this.reason,
      deviceCount: deviceCount ?? this.deviceCount,
      idempotencyKey: idempotencyKey ?? this.idempotencyKey,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
