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
import 'enums/team_kind.dart' as _i2;

/// **Команда — список людей, а НЕ чат**
/// (см. `DESIGN_TEAMS_AND_CONTACT_SHARING.md`).
///
/// Задача: новый человек в тенанте видит пустой список людей и найти
/// кого-либо может только по email, который ещё надо у кого-то спросить.
/// Комната такую роль не исполняет: чтобы познакомить людей, пришлось бы
/// завести переписку, которая никому не нужна. Команда — тот же
/// контейнер («вместе ⇒ знакомы»), но без переписки.
///
/// **Членство считается ПРИ ЧТЕНИИ, а не копируется в contact_link.**
/// Владелец требовал постоянную синхронизацию, а не разовую: копии
/// пришлось бы догонять при каждом изменении состава, и «исключили —
/// пропал» перестало бы работать задним числом. Вычисление всегда свежее
/// по определению.
///
/// **Команда не даёт доверия.** Видимость и возможность написать — да;
/// contacts-поля визитки и обход `whoCanMessageMe` — нет, это остаётся за
/// явной заявкой ([ContactRequest]). Иначе добавление в команду стало бы
/// обходом чужой приватности.
///
/// Команда живёт ВНУТРИ тенанта: участник — ссылка на `MessengerUser`, а
/// тот принадлежит тенанту. Кросс-тенантных команд не будет — это та же
/// изоляция, на которой стоит платформа.
abstract class Team implements _i1.SerializableModel {
  Team._({
    this.id,
    required this.tenantId,
    required this.name,
    this.description,
    required this.kind,
    this.createdByMessengerUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Team({
    int? id,
    required int tenantId,
    required String name,
    String? description,
    required _i2.TeamKind kind,
    int? createdByMessengerUserId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _TeamImpl;

  factory Team.fromJson(Map<String, dynamic> jsonSerialization) {
    return Team(
      id: jsonSerialization['id'] as int?,
      tenantId: jsonSerialization['tenantId'] as int,
      name: jsonSerialization['name'] as String,
      description: jsonSerialization['description'] as String?,
      kind: _i2.TeamKind.fromJson((jsonSerialization['kind'] as String)),
      createdByMessengerUserId:
          jsonSerialization['createdByMessengerUserId'] as int?,
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

  /// FK на Tenant. Cascade-delete: команды уходят вместе с тенантом.
  int tenantId;

  String name;

  String? description;

  /// См. [TeamKind]: `org` — справочник тенанта (только админ платформы),
  /// `private` — своя команда пользователя (этап 3).
  _i2.TeamKind kind;

  /// Кто завёл — для аудита. Без FK-связи намеренно: удаление автора не
  /// должна ни ронять команду, ни тянуть за собой каскад (тот же приём,
  /// что в `task_links.createdByMessengerUserId`).
  int? createdByMessengerUserId;

  DateTime createdAt;

  DateTime updatedAt;

  /// Returns a shallow copy of this [Team]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  Team copyWith({
    int? id,
    int? tenantId,
    String? name,
    String? description,
    _i2.TeamKind? kind,
    int? createdByMessengerUserId,
    DateTime? createdAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'Team',
      if (id != null) 'id': id,
      'tenantId': tenantId,
      'name': name,
      if (description != null) 'description': description,
      'kind': kind.toJson(),
      if (createdByMessengerUserId != null)
        'createdByMessengerUserId': createdByMessengerUserId,
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

class _TeamImpl extends Team {
  _TeamImpl({
    int? id,
    required int tenantId,
    required String name,
    String? description,
    required _i2.TeamKind kind,
    int? createdByMessengerUserId,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         tenantId: tenantId,
         name: name,
         description: description,
         kind: kind,
         createdByMessengerUserId: createdByMessengerUserId,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [Team]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  Team copyWith({
    Object? id = _Undefined,
    int? tenantId,
    String? name,
    Object? description = _Undefined,
    _i2.TeamKind? kind,
    Object? createdByMessengerUserId = _Undefined,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Team(
      id: id is int? ? id : this.id,
      tenantId: tenantId ?? this.tenantId,
      name: name ?? this.name,
      description: description is String? ? description : this.description,
      kind: kind ?? this.kind,
      createdByMessengerUserId: createdByMessengerUserId is int?
          ? createdByMessengerUserId
          : this.createdByMessengerUserId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
