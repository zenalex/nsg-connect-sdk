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

/// Продукт нельзя удалить: на нём есть живое.
///
/// Семь из восьми ссылок на продукт — `SET NULL` (комнаты, обращения,
/// боты, идентичности, устройства, вебхуки, конфиг таск-менеджера).
/// Значит «просто удалить» не удалило бы их, а МОЛЧА осиротило: комнаты
/// остались бы без продукта, обращения — без адресата. Поэтому удаление
/// разрешено только пустому продукту, а этот отказ несёт счётчики того,
/// что мешает: администратору нужно знать, ЧТО именно разбирать, а не
/// «действие не удалось».
///
/// Провижн (команда поддержки, issued-токены) сюда НЕ входит — он
/// удаляется вместе с продуктом: это выданные наружу ключи и настройка
/// поддержки, а не переписка людей.
abstract class ProductInUseException
    implements _i1.SerializableException, _i1.SerializableModel {
  ProductInUseException._({
    required this.productExternalKey,
    required this.rooms,
    required this.tickets,
    required this.bots,
    required this.identities,
    required this.devices,
    required this.webhooks,
  });

  factory ProductInUseException({
    required String productExternalKey,
    required int rooms,
    required int tickets,
    required int bots,
    required int identities,
    required int devices,
    required int webhooks,
  }) = _ProductInUseExceptionImpl;

  factory ProductInUseException.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return ProductInUseException(
      productExternalKey: jsonSerialization['productExternalKey'] as String,
      rooms: jsonSerialization['rooms'] as int,
      tickets: jsonSerialization['tickets'] as int,
      bots: jsonSerialization['bots'] as int,
      identities: jsonSerialization['identities'] as int,
      devices: jsonSerialization['devices'] as int,
      webhooks: jsonSerialization['webhooks'] as int,
    );
  }

  String productExternalKey;

  int rooms;

  int tickets;

  int bots;

  int identities;

  int devices;

  int webhooks;

  /// Returns a shallow copy of this [ProductInUseException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  ProductInUseException copyWith({
    String? productExternalKey,
    int? rooms,
    int? tickets,
    int? bots,
    int? identities,
    int? devices,
    int? webhooks,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ProductInUseException',
      'productExternalKey': productExternalKey,
      'rooms': rooms,
      'tickets': tickets,
      'bots': bots,
      'identities': identities,
      'devices': devices,
      'webhooks': webhooks,
    };
  }

  @override
  String toString() {
    return 'ProductInUseException(productExternalKey: $productExternalKey, rooms: $rooms, tickets: $tickets, bots: $bots, identities: $identities, devices: $devices, webhooks: $webhooks)';
  }
}

class _ProductInUseExceptionImpl extends ProductInUseException {
  _ProductInUseExceptionImpl({
    required String productExternalKey,
    required int rooms,
    required int tickets,
    required int bots,
    required int identities,
    required int devices,
    required int webhooks,
  }) : super._(
         productExternalKey: productExternalKey,
         rooms: rooms,
         tickets: tickets,
         bots: bots,
         identities: identities,
         devices: devices,
         webhooks: webhooks,
       );

  /// Returns a shallow copy of this [ProductInUseException]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  ProductInUseException copyWith({
    String? productExternalKey,
    int? rooms,
    int? tickets,
    int? bots,
    int? identities,
    int? devices,
    int? webhooks,
  }) {
    return ProductInUseException(
      productExternalKey: productExternalKey ?? this.productExternalKey,
      rooms: rooms ?? this.rooms,
      tickets: tickets ?? this.tickets,
      bots: bots ?? this.bots,
      identities: identities ?? this.identities,
      devices: devices ?? this.devices,
      webhooks: webhooks ?? this.webhooks,
    );
  }
}
