import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger/src/admin/nsg_messenger_platform_admin.dart';

/// **TASK78 п.3**: обвязка платформенной админки секретов тенантов.
///
/// Ключевые контракты:
///   * isPlatformAdmin / listTenants деградируют сбой и старый сервер в
///     false/пусто (гейт-методы UI, их отказ — норма);
///   * мутации (enableAndGenerate/rotateSecret/disable) ошибок НЕ глотают
///     — молча потерять результат генерации секрета хуже, чем ошибка;
///   * rotateSecret принимает МИНУТЫ и шлёт на сервер СЕКУНДЫ.
void main() {
  ConnectTenantStatus status(String key, {bool enabled = true}) =>
      ConnectTenantStatus(
        tenantExternalKey: key,
        tenantName: 'T $key',
        enabled: enabled,
        hasSecret: enabled,
      );

  NsgMessengerPlatformAdmin makeAdmin({
    IsPlatformAdminRpc? isPlatformAdminRpc,
    ListTenantsRpc? listTenantsRpc,
    EnableAndGenerateRpc? enableAndGenerateRpc,
    RotateTenantSecretRpc? rotateSecretRpc,
    ListTenantAuditEventsRpc? listAuditEventsRpc,
  }) => NsgMessengerPlatformAdmin.withRpcs(
    isPlatformAdminRpc: isPlatformAdminRpc ?? () async => true,
    listTenantsRpc: listTenantsRpc ?? () async => const [],
    enableAndGenerateRpc:
        enableAndGenerateRpc ??
        ({required String tenantExternalKey}) => throw UnimplementedError(),
    rotateSecretRpc:
        rotateSecretRpc ??
        ({required String tenantExternalKey, int? graceSeconds}) =>
            throw UnimplementedError(),
    disableRpc: ({required String tenantExternalKey}) async {},
    statusRpc: ({required String tenantExternalKey}) =>
        throw UnimplementedError(),
    listAuditEventsRpc:
        listAuditEventsRpc ??
        ({required String tenantExternalKey, required int limit}) async =>
            const <ConnectKeyAuditEvent>[],
  );

  test('isPlatformAdmin: ответ сервера проходит насквозь', () async {
    expect(await makeAdmin().isPlatformAdmin(), isTrue);
    expect(
      await makeAdmin(isPlatformAdminRpc: () async => false)
          .isPlatformAdmin(),
      isFalse,
    );
  });

  test('isPlatformAdmin: RPC нет/упал (старый сервер) → false, '
      'не исключение — пункт меню просто не показывается', () async {
    final admin = makeAdmin(
      isPlatformAdminRpc: () => throw StateError('нет такого метода'),
    );
    expect(await admin.isPlatformAdmin(), isFalse);
  });

  test('listTenants: отдаёт статусы сервера', () async {
    final admin = makeAdmin(
      listTenantsRpc: () async => [status('nsg'), status('t112', enabled: false)],
    );
    final tenants = await admin.listTenants();
    expect(tenants.map((t) => t.tenantExternalKey), ['nsg', 't112']);
  });

  test('listTenants: сбой RPC → пусто, деградация без поломки', () async {
    final admin = makeAdmin(
      listTenantsRpc: () => throw StateError('сеть упала'),
    );
    expect(await admin.listTenants(), isEmpty);
  });

  test('enableAndGenerate: секрет проходит насквозь (показ один раз — '
      'забота экрана, обвязка не хранит)', () async {
    String? seenKey;
    final admin = makeAdmin(
      enableAndGenerateRpc: ({required String tenantExternalKey}) async {
        seenKey = tenantExternalKey;
        return 'cst_fresh';
      },
    );
    expect(await admin.enableAndGenerate(tenantExternalKey: 'nsg'), 'cst_fresh');
    expect(seenKey, 'nsg');
  });

  test('enableAndGenerate: ошибка НЕ глотается', () async {
    final admin = makeAdmin(
      enableAndGenerateRpc: ({required String tenantExternalKey}) =>
          throw StateError('boom'),
    );
    expect(
      () => admin.enableAndGenerate(tenantExternalKey: 'nsg'),
      throwsStateError,
    );
  });

  test('rotateSecret: минуты конвертируются в секунды; дефолт 5 мин = 300 с',
      () async {
    final seen = <int?>[];
    final admin = makeAdmin(
      rotateSecretRpc:
          ({required String tenantExternalKey, int? graceSeconds}) async {
            seen.add(graceSeconds);
            return 'cst_rotated';
          },
    );
    expect(await admin.rotateSecret(tenantExternalKey: 'nsg'), 'cst_rotated');
    await admin.rotateSecret(tenantExternalKey: 'nsg', graceMinutes: 30);
    expect(seen, [300, 1800]);
  });

  test('listAuditEvents: дефолтный limit 50 доходит до RPC', () async {
    int? seenLimit;
    final admin = makeAdmin(
      listAuditEventsRpc:
          ({required String tenantExternalKey, required int limit}) async {
            seenLimit = limit;
            return const <ConnectKeyAuditEvent>[];
          },
    );
    await admin.listAuditEvents(tenantExternalKey: 'nsg');
    expect(seenLimit, 50);
  });
}
