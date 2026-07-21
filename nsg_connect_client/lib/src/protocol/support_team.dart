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

/// **TASK43**: операторская команда поддержки — одна на пару
/// `(tenantId, productId)`. Заменяет статический env-конфиг
/// `SUPPORT_OPERATOR_<PRODUCT>` (TASK39 MVP): вместо резолва списка
/// email из окружения при каждом открытии support-комнаты, состав
/// команды хранится в БД и управляется владельцем из Chatista.
///
/// Участники — [SupportTeamMember] (людей-операторов И бот продукта).
/// При создании support-комнаты (`RoomService.openSupportChat`) в неё
/// добавляются ВСЕ участники команды; изменение состава синхронизируется
/// во все существующие support-комнаты продукта (best-effort, batched).
///
/// **Seed из env**: при старте сервера, если для продукта задан
/// `SUPPORT_OPERATOR_<KEY>` и команды в БД ЕЩЁ НЕТ — команда создаётся
/// из резолвнутых email (первый = owner). Далее env — только seed:
/// БД главнее (см. `SupportTeamService.seedFromEnv`).
abstract class SupportTeam implements _i1.SerializableModel {
  SupportTeam._({
    this.id,
    required this.tenantId,
    required this.productId,
    int? escalationTimeoutMinutes,
    required this.createdAt,
    required this.updatedAt,
  }) : escalationTimeoutMinutes = escalationTimeoutMinutes ?? 60;

  factory SupportTeam({
    int? id,
    required int tenantId,
    required int productId,
    int? escalationTimeoutMinutes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _SupportTeamImpl;

  factory SupportTeam.fromJson(Map<String, dynamic> jsonSerialization) {
    return SupportTeam(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      productId: jsonSerialization['productId'] as int,
      escalationTimeoutMinutes:
          jsonSerialization['escalationTimeoutMinutes'] as int?,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// FK на Tenant. Cascade-delete: команда удаляется вместе с tenant-ом.
  int tenantId;

  /// FK на Product. Cascade-delete: команда удаляется вместе с продуктом.
  /// Одна команда на продукт (см. unique-индекс).
  int productId;

  /// **TASK48**: порог авто-эскалации в минутах — сколько support-чат
  /// ждёт ответа фронт-линии, прежде чем `SupportEscalationSweepFutureCall`
  /// подключит следующий тир. Настраивается owner'ом per-project. Дефолт
  /// 60. ALTER на непустую таблицу требует DB-дефолта.
  int escalationTimeoutMinutes;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [SupportTeam]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  SupportTeam copyWith({
    int? id,
    int? tenantId,
    int? productId,
    int? escalationTimeoutMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'SupportTeam',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      'productId': productId,
      'escalationTimeoutMinutes': escalationTimeoutMinutes,
      'createdAt': createdAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _SupportTeamImpl extends SupportTeam {
  _SupportTeamImpl({
    int? id,
    required int tenantId,
    required int productId,
    int? escalationTimeoutMinutes,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         tenantId: tenantId,
         productId: productId,
         escalationTimeoutMinutes: escalationTimeoutMinutes,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [SupportTeam]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  SupportTeam copyWith({
    Object? id = _Undefined,
    int? tenantId,
    int? productId,
    int? escalationTimeoutMinutes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SupportTeam(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      productId: productId ?? this.productId,
      escalationTimeoutMinutes:
          escalationTimeoutMinutes ?? this.escalationTimeoutMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
