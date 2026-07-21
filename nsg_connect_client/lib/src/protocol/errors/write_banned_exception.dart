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

/// **Write-ban**: участнику временно/постоянно запрещено писать в эту
/// комнату (админом/владельцем). Читать может — membership жив.
/// Клиент показывает «Вам запрещено писать до <until>»; year ≥ 9000 —
/// «навсегда».
abstract class WriteBannedException
    implements _i1.SerializableException, _i1.SerializableModel {
  WriteBannedException._({required this.until});

  factory WriteBannedException({required DateTime until}) =
      _WriteBannedExceptionImpl;

  factory WriteBannedException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return WriteBannedException(
      until: _i1.DateTimeJsonExtension.fromJson(jsonSerialization['until']),
    );
  }

  DateTime until;

  /// Returns a shallow copy of this [WriteBannedException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  WriteBannedException copyWith({DateTime? until});
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'WriteBannedException',
      'until': until.toJson(),
    };
  }

  @override
  String toString() {
    return 'WriteBannedException(until: $until)';
  }
}

class _WriteBannedExceptionImpl extends WriteBannedException {
  _WriteBannedExceptionImpl({required DateTime until}) : super._(until: until);

  /// Returns a shallow copy of this [WriteBannedException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  WriteBannedException copyWith({DateTime? until}) {
    return WriteBannedException(until: until ?? this.until);
  }
}
