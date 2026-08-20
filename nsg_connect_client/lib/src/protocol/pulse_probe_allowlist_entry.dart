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

/// **Куда пробам вообще разрешено ходить** (TASK94, issue #108).
///
/// Таблица, а не env — вопреки первому предложению интегратора. Env у нас
/// меняется пересборкой и рестартом контейнера (так живёт
/// `PULSE_ADMIN_EMAILS`), а этот список будет меняться часто: 15 endpoint
/// сейчас и больше потом. При этом сам интегратор требовал auditable —
/// с env эти два требования несовместимы.
///
/// Список СУЖАЕТ, а не отменяет запреты: адрес из петли или внутренней сети
/// не станет разрешённым оттого, что кто-то добавил его сюда (см.
/// `pulse_probe_target_policy.dart`).
abstract class PulseProbeAllowlistEntry implements _i1.SerializableModel {
  PulseProbeAllowlistEntry._({
    this.id,
    required this.address,
    this.prefixLength,
    required this.port,
    this.note,
    required this.createdBy,
    required this.createdAt,
  });

  factory PulseProbeAllowlistEntry({
    int? id,
    required String address,
    int? prefixLength,
    required int port,
    String? note,
    required int createdBy,
    required DateTime createdAt,
  }) = _PulseProbeAllowlistEntryImpl;

  factory PulseProbeAllowlistEntry.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return PulseProbeAllowlistEntry(
      id: jsonSerialization['id'] as int?,
      address: jsonSerialization['address'] as String,
      prefixLength: jsonSerialization['prefixLength'] as int?,
      port: jsonSerialization['port'] as int,
      note: jsonSerialization['note'] as String?,
      createdBy: jsonSerialization['createdBy'] as int,
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  /// The database id, set if the object has been inserted into the
  /// database or if it has been fetched from the database. Otherwise,
  /// the id will be null.
  int? id;

  /// Адрес или сеть. Строкой, а не inet: у Serverpod своего типа нет, а
  /// разбор всё равно наш собственный — он строже системного нарочно.
  String address;

  /// Длина маски. `null` — точный адрес.
  int? prefixLength;

  /// Порт обязателен. «Любой порт» не поддерживаем: разрешив хост целиком,
  /// мы разрешили бы и то, что появится на нём завтра.
  int port;

  /// Зачем эта строка заведена — человеку, который через полгода будет
  /// решать, можно ли её убрать.
  String? note;

  int createdBy;

  DateTime createdAt;

  /// Returns a shallow copy of this [PulseProbeAllowlistEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PulseProbeAllowlistEntry copyWith({
    int? id,
    String? address,
    int? prefixLength,
    int? port,
    String? note,
    int? createdBy,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PulseProbeAllowlistEntry',
      if (id != null) 'id': id,
      'address': address,
      if (prefixLength != null) 'prefixLength': prefixLength,
      'port': port,
      if (note != null) 'note': note,
      'createdBy': createdBy,
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _PulseProbeAllowlistEntryImpl extends PulseProbeAllowlistEntry {
  _PulseProbeAllowlistEntryImpl({
    int? id,
    required String address,
    int? prefixLength,
    required int port,
    String? note,
    required int createdBy,
    required DateTime createdAt,
  }) : super._(
         id: id,
         address: address,
         prefixLength: prefixLength,
         port: port,
         note: note,
         createdBy: createdBy,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [PulseProbeAllowlistEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PulseProbeAllowlistEntry copyWith({
    Object? id = _Undefined,
    String? address,
    Object? prefixLength = _Undefined,
    int? port,
    Object? note = _Undefined,
    int? createdBy,
    DateTime? createdAt,
  }) {
    return PulseProbeAllowlistEntry(
      id: id is int? ? id : this.id,
      address: address ?? this.address,
      prefixLength: prefixLength is int? ? prefixLength : this.prefixLength,
      port: port ?? this.port,
      note: note is String? ? note : this.note,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
