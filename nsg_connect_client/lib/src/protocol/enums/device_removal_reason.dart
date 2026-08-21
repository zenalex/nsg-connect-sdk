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

/// Почему push-регистрация исчезла (issue #150).
///
/// Раньше строку `device_registrations` просто удаляли, и «токен умер у
/// провайдера» становилось неотличимо от «мы убили живой телефон своей
/// ошибкой». Причина обязана быть записана в момент снятия — потом её
/// восстановить неоткуда.
///
///   * `providerUnregistered` — провайдер сказал `UNREGISTERED` /
///     `NOT_FOUND`: приложение удалили или токен отозван. Честная смерть,
///     удалять правильно.
///   * `providerInvalidArgument` — провайдер сказал `INVALID_ARGUMENT`.
///     **Подозрительно**: этот же код FCM отдаёт на кривую нагрузку, то
///     есть наша опечатка в поле выглядела бы как «люди сами вышли»
///     (риск записан в `TASK_TITAN_PRODUCT_PUSH01` §8). Первое такое
///     срабатывание регистрацию НЕ удаляет — только помечает.
///   * `clientLogout` — приложение само отозвало регистрацию (выход из
///     аккаунта, `MessengerRuntime.dispose`). Ожидаемо и безобидно, но
///     запись нужна: иначе «была и исчезла» и «не было никогда» снова
///     выглядят одинаково.
///   * `staleCleanup` — плановая уборка засидевшихся регистраций
///     (`CleanupStaleDeviceRegistrationsFutureCall`, 60 дней).
enum DeviceRemovalReason implements _i1.SerializableModel {
  providerUnregistered,
  providerInvalidArgument,
  clientLogout,
  staleCleanup;

  static DeviceRemovalReason fromJson(String name) {
    switch (name) {
      case 'providerUnregistered':
        return DeviceRemovalReason.providerUnregistered;
      case 'providerInvalidArgument':
        return DeviceRemovalReason.providerInvalidArgument;
      case 'clientLogout':
        return DeviceRemovalReason.clientLogout;
      case 'staleCleanup':
        return DeviceRemovalReason.staleCleanup;
      default:
        throw ArgumentError(
          'Value "$name" cannot be converted to "DeviceRemovalReason"',
        );
    }
  }

  @override
  String toJson() => name;

  @override
  String toString() => name;
}
