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

/// **TASK52 итер.2**: статус карточки-заявки (message-request).
///   * pending — отправлена, ждёт ответа;
///   * accepted — принята (создан взаимный ContactLink + чат);
///   * declined — отклонена (cooldown на повтор, §8).
enum ContactRequestStatus implements _i1.SerializableModel {
  pending,
  accepted,
  declined;

  static ContactRequestStatus fromJson(String name) {
    switch (name) {
      case 'pending':
        return ContactRequestStatus.pending;
      case 'accepted':
        return ContactRequestStatus.accepted;
      case 'declined':
        return ContactRequestStatus.declined;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "ContactRequestStatus"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
