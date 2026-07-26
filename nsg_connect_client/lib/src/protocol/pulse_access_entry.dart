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

/// **TASK79 п.9**: эффективная роль каллера на одном объекте дерева.
/// `listMyAccess()` отдаёт такой список — по нему SDK прячет кнопки
/// («Пересоздать токен» у viewer-а и т.п.).
///
/// **Почему отдельный список, а не поле `myRole` на `PulseFolder`/
/// `PulseMonitor`**: эти два класса ходят ещё и в beat-роут, свипер и
/// realtime-стрим, где «роль» не определена в принципе (у beat-а нет
/// каллера). Поле, осмысленное лишь в трети путей, — приглашение
/// прочитать его в остальных двух.
///
/// Старые клиенты про этот эндпоинт не знают и просто не вызывают его —
/// совместимость не ломается.
abstract class PulseAccessEntry implements _i1.SerializableModel {
  PulseAccessEntry._({
    required this.targetKind,
    required this.targetId,
    required this.role,
    bool? inherited,
  }) : inherited = inherited ?? false;

  factory PulseAccessEntry({
    required String targetKind,
    required int targetId,
    required String role,
    bool? inherited,
  }) = _PulseAccessEntryImpl;

  factory PulseAccessEntry.fromJson(Map<String, dynamic> jsonSerialization) {
    return PulseAccessEntry(
      targetKind: jsonSerialization['targetKind'] as String,
      targetId: jsonSerialization['targetId'] as int,
      role: jsonSerialization['role'] as String,
      inherited: jsonSerialization['inherited'] == null
          ? null
          : _i1.BoolJsonExtension.fromJson(jsonSerialization['inherited']),
    );
  }

  /// `folder` | `monitor`.
  String targetKind;

  int targetId;

  /// `owner` | `admin` | `viewer`.
  String role;

  /// `true` — роль унаследована от папки-предка, а не выдана на объекте.
  bool inherited;

  /// Returns a shallow copy of this [PulseAccessEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  PulseAccessEntry copyWith({
    String? targetKind,
    int? targetId,
    String? role,
    bool? inherited,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'PulseAccessEntry',
      'targetKind': targetKind,
      'targetId': targetId,
      'role': role,
      'inherited': inherited,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _PulseAccessEntryImpl extends PulseAccessEntry {
  _PulseAccessEntryImpl({
    required String targetKind,
    required int targetId,
    required String role,
    bool? inherited,
  }) : super._(
         targetKind: targetKind,
         targetId: targetId,
         role: role,
         inherited: inherited,
       );

  /// Returns a shallow copy of this [PulseAccessEntry]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  PulseAccessEntry copyWith({
    String? targetKind,
    int? targetId,
    String? role,
    bool? inherited,
  }) {
    return PulseAccessEntry(
      targetKind: targetKind ?? this.targetKind,
      targetId: targetId ?? this.targetId,
      role: role ?? this.role,
      inherited: inherited ?? this.inherited,
    );
  }
}
