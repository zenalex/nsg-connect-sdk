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

/// **TASK46 (история звонков)**: итоговый статус записи `CallHistoryEntry`.
/// Обновляется server-side по ходу сигналинга (invite→ringing,
/// answer→answeredAt, hangup/reject→финал):
///   * ringing   — invite отправлен, ещё не отвечен и не завершён;
///   * completed — был answer, затем hangup (есть `durationSeconds`);
///   * missed    — завершён БЕЗ answer (hangup/таймаут): для callee —
///                 «пропущенный», для caller — «не отвечено»;
///   * declined  — callee явно отклонил (reject);
///   * failed    — ошибка установления (резерв, на будущее).
///
/// Направление (входящий/исходящий) НЕ храним — выводится per-viewer
/// на клиенте (viewer==caller → исходящий).
enum CallStatus implements _i1.SerializableModel {
  ringing,
  completed,
  missed,
  declined,
  failed;

  static CallStatus fromJson(String name) {
    switch (name) {
      case 'ringing':
        return CallStatus.ringing;
      case 'completed':
        return CallStatus.completed;
      case 'missed':
        return CallStatus.missed;
      case 'declined':
        return CallStatus.declined;
      case 'failed':
        return CallStatus.failed;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "CallStatus"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
