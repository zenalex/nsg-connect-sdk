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

/// **TASK52 итер.2**: отношение текущего пользователя к другому —
/// для UI (профиль, интро-карточка): кнопки «добавить/удалить контакт»,
/// «заблокировать/разблокировать», состояние trust.
abstract class ContactRelation implements _i1.SerializableModel {
  ContactRelation._({
    required this.otherMessengerUserId,
    required this.isContact,
    required this.blockedByMe,
  });

  factory ContactRelation({
    required int otherMessengerUserId,
    required bool isContact,
    required bool blockedByMe,
  }) = _ContactRelationImpl;

  factory ContactRelation.fromJson(Map<String, dynamic> jsonSerialization) {
    return ContactRelation(
      otherMessengerUserId: jsonSerialization['otherMessengerUserId'] as int,
      isContact: _i1.BoolJsonExtension.fromJson(jsonSerialization['isContact']),
      blockedByMe: _i1.BoolJsonExtension.fromJson(
        jsonSerialization['blockedByMe'],
      ),
    );
  }

  int otherMessengerUserId;

  /// Симметричный trust (связь в любую сторону).
  bool isContact;

  /// Я заблокировал этого пользователя.
  bool blockedByMe;

  /// Returns a shallow copy of this [ContactRelation]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ContactRelation copyWith({
    int? otherMessengerUserId,
    bool? isContact,
    bool? blockedByMe,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ContactRelation',
      'otherMessengerUserId': otherMessengerUserId,
      'isContact': isContact,
      'blockedByMe': blockedByMe,
    };
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _ContactRelationImpl extends ContactRelation {
  _ContactRelationImpl({
    required int otherMessengerUserId,
    required bool isContact,
    required bool blockedByMe,
  }) : super._(
         otherMessengerUserId: otherMessengerUserId,
         isContact: isContact,
         blockedByMe: blockedByMe,
       );

  /// Returns a shallow copy of this [ContactRelation]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ContactRelation copyWith({
    int? otherMessengerUserId,
    bool? isContact,
    bool? blockedByMe,
  }) {
    return ContactRelation(
      otherMessengerUserId: otherMessengerUserId ?? this.otherMessengerUserId,
      isContact: isContact ?? this.isContact,
      blockedByMe: blockedByMe ?? this.blockedByMe,
    );
  }
}
