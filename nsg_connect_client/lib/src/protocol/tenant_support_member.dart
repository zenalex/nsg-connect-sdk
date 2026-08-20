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

/// **Участник поддержки на уровне ТЕНАНТА.**
///
/// Одни и те же люди ведут поддержку всех продуктов заказчика, а
/// вписывать их приходилось в каждую команду продукта заново (наблюдалось:
/// пятеро вбиты вручную в одну команду, и та же работа ждала в следующей).
///
/// Наследование ЖИВОЕ: человек числится в команде каждого продукта
/// тенанта, пока он в этом списке. Убрали отсюда — исчез во всех командах
/// сразу; появился новый продукт — получил его автоматически. Поэтому
/// здесь нет `teamId`: запись не дублируется в команды, а подмешивается к
/// их составу при чтении.
///
/// `tier` — уровень по умолчанию для всех продуктов (1 = фронт-линия,
/// 2 = эскалация). Роль НЕ храним: владелец — свойство конкретной команды
/// (у продуктов разные ответственные), а тенантный участник приходит
/// обычным оператором.
abstract class TenantSupportMember implements _i1.SerializableModel {
  TenantSupportMember._({
    this.id,
    required this.tenantId,
    required this.messengerUserId,
    int? tier,
    this.addedByEmail,
    required this.createdAt,
  }) : tier = tier ?? 1;

  factory TenantSupportMember({
    int? id,
    required int tenantId,
    required int messengerUserId,
    int? tier,
    String? addedByEmail,
    required DateTime createdAt,
  }) = _TenantSupportMemberImpl;

  factory TenantSupportMember.fromJson(Map<String, dynamic> jsonSerialization) {
    return TenantSupportMember(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      messengerUserId: jsonSerialization['messengerUserId'] as int,
      tier: jsonSerialization['tier'] as int?,
      addedByEmail: jsonSerialization['addedByEmail'] as String?,
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

  int messengerUserId;

  int tier;

  /// Кто добавил — для аудита (как в support_team_members).
  String? addedByEmail;

  DateTime createdAt;

  /// Returns a shallow copy of this [TenantSupportMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  TenantSupportMember copyWith({
    int? id,
    int? tenantId,
    int? messengerUserId,
    int? tier,
    String? addedByEmail,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'TenantSupportMember',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      'messengerUserId': messengerUserId,
      'tier': tier,
      if (addedByEmail != null) 'addedByEmail': addedByEmail,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _TenantSupportMemberImpl extends TenantSupportMember {
  _TenantSupportMemberImpl({
    int? id,
    required int tenantId,
    required int messengerUserId,
    int? tier,
    String? addedByEmail,
    required DateTime createdAt,
  }) : super._(
         id: id,
         tenantId: tenantId,
         messengerUserId: messengerUserId,
         tier: tier,
         addedByEmail: addedByEmail,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [TenantSupportMember]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  TenantSupportMember copyWith({
    Object? id = _Undefined,
    int? tenantId,
    int? messengerUserId,
    int? tier,
    Object? addedByEmail = _Undefined,
    DateTime? createdAt,
  }) {
    return TenantSupportMember(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      messengerUserId: messengerUserId ?? this.messengerUserId,
      tier: tier ?? this.tier,
      addedByEmail: addedByEmail is String? ? addedByEmail : this.addedByEmail,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
