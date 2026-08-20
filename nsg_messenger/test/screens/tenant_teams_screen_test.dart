import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/admin/nsg_messenger_platform_admin.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/screens/tenant_teams_screen.dart';

/// **Экран команд тенанта** (этап 2).
///
/// Проверяем то, что ломается тише всего:
///
///   * КАЖДЫЙ вызов уходит с ключом тенанта. Забудешь его — сервер начнёт
///     резолвить команду по одному номеру, и админ, работающий с одним
///     заказчиком, правит справочник другого. Ровно этот класс ошибки уже
///     ловили на поддержке;
///   * размер состава в строке команды обновляется после правки — иначе
///     админ видит старое число и думает, что добавление не прошло;
///   * тёзка объясняется отдельной причиной, а не общим «не получилось».
void main() {
  TeamView team(int id, String name, int count) =>
      TeamView(id: id, name: name, kind: TeamKind.org, memberCount: count);

  Widget host(NsgMessengerPlatformAdmin admin) => MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: NsgL10n.localizationsDelegates,
    supportedLocales: NsgL10n.supportedLocales,
    home: TenantTeamsScreen(
      tenantExternalKey: 'nsg',
      tenantName: 'НСГ',
      admin: admin,
    ),
  );

  testWidgets('список команд показывает размер состава', (tester) async {
    final admin = NsgMessengerPlatformAdmin.withRpcs(
      isPlatformAdminRpc: () async => true,
      listDeliveryHealthRpc: () async => const <ProductDeliveryHealth>[],
      listTenantsRpc: () async => const <ConnectTenantStatus>[],
      enableAndGenerateRpc: ({required String tenantExternalKey}) async => '',
      rotateSecretRpc:
          ({required String tenantExternalKey, int? graceSeconds}) async => '',
      disableRpc: ({required String tenantExternalKey}) async {},
      statusRpc: ({required String tenantExternalKey}) async =>
          throw UnimplementedError(),
      listAuditEventsRpc:
          ({required String tenantExternalKey, required int limit}) async =>
              const <ConnectKeyAuditEvent>[],
      listTeamsRpc: ({required String tenantExternalKey}) async => [
        team(1, 'Компания', 12),
      ],
    );

    await tester.pumpWidget(host(admin));
    await tester.pumpAndSettle();

    expect(find.text('Компания'), findsOneWidget);
    expect(find.textContaining('12'), findsOneWidget);
  });

  testWidgets('пусто — экран объясняет последствие, а не молчит', (
    tester,
  ) async {
    final admin = NsgMessengerPlatformAdmin.withRpcs(
      isPlatformAdminRpc: () async => true,
      listDeliveryHealthRpc: () async => const <ProductDeliveryHealth>[],
      listTenantsRpc: () async => const <ConnectTenantStatus>[],
      enableAndGenerateRpc: ({required String tenantExternalKey}) async => '',
      rotateSecretRpc:
          ({required String tenantExternalKey, int? graceSeconds}) async => '',
      disableRpc: ({required String tenantExternalKey}) async {},
      statusRpc: ({required String tenantExternalKey}) async =>
          throw UnimplementedError(),
      listAuditEventsRpc:
          ({required String tenantExternalKey, required int limit}) async =>
              const <ConnectKeyAuditEvent>[],
      listTeamsRpc: ({required String tenantExternalKey}) async =>
          const <TeamView>[],
    );

    await tester.pumpWidget(host(admin));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('новичок увидит пустой список'),
      findsOneWidget,
      reason: 'пустой справочник — это и есть исходная боль',
    );
  });

  testWidgets('запрос состава уходит с ключом тенанта', (tester) async {
    // Без ключа сервер резолвил бы команду по одному номеру — и админ
    // одного заказчика открыл бы справочник другого.
    final seenKeys = <String>[];
    final admin = NsgMessengerPlatformAdmin.withRpcs(
      isPlatformAdminRpc: () async => true,
      listDeliveryHealthRpc: () async => const <ProductDeliveryHealth>[],
      listTenantsRpc: () async => const <ConnectTenantStatus>[],
      enableAndGenerateRpc: ({required String tenantExternalKey}) async => '',
      rotateSecretRpc:
          ({required String tenantExternalKey, int? graceSeconds}) async => '',
      disableRpc: ({required String tenantExternalKey}) async {},
      statusRpc: ({required String tenantExternalKey}) async =>
          throw UnimplementedError(),
      listAuditEventsRpc:
          ({required String tenantExternalKey, required int limit}) async =>
              const <ConnectKeyAuditEvent>[],
      listTeamsRpc: ({required String tenantExternalKey}) async {
        seenKeys.add(tenantExternalKey);
        return [team(7, 'Разработка', 1)];
      },
      listTeamMembersRpc:
          ({required String tenantExternalKey, required int teamId}) async {
            seenKeys.add(tenantExternalKey);
            return [
              TeamMemberView(
                messengerUserId: 5,
                displayName: 'Аня',
                role: TeamMemberRole.member,
              ),
            ];
          },
    );

    await tester.pumpWidget(host(admin));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Разработка'));
    await tester.pumpAndSettle();

    expect(find.text('Аня'), findsOneWidget);
    expect(
      seenKeys,
      everyElement('nsg'),
      reason: 'ни один вызов не должен идти без тенанта',
    );
  });

  testWidgets('после правки состава список перечитывается', (tester) async {
    // В строке команды показан РАЗМЕР состава, а меняли его на соседнем
    // экране: без перечитывания админ видит старое число и решает, что
    // добавление не прошло.
    var calls = 0;
    final admin = NsgMessengerPlatformAdmin.withRpcs(
      isPlatformAdminRpc: () async => true,
      listDeliveryHealthRpc: () async => const <ProductDeliveryHealth>[],
      listTenantsRpc: () async => const <ConnectTenantStatus>[],
      enableAndGenerateRpc: ({required String tenantExternalKey}) async => '',
      rotateSecretRpc:
          ({required String tenantExternalKey, int? graceSeconds}) async => '',
      disableRpc: ({required String tenantExternalKey}) async {},
      statusRpc: ({required String tenantExternalKey}) async =>
          throw UnimplementedError(),
      listAuditEventsRpc:
          ({required String tenantExternalKey, required int limit}) async =>
              const <ConnectKeyAuditEvent>[],
      listTeamsRpc: ({required String tenantExternalKey}) async {
        calls++;
        return [team(7, 'Разработка', calls == 1 ? 1 : 2)];
      },
      listTeamMembersRpc:
          ({required String tenantExternalKey, required int teamId}) async =>
              const <TeamMemberView>[],
    );

    await tester.pumpWidget(host(admin));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Разработка'));
    await tester.pumpAndSettle();
    // Не `pageBack()`: он ищет кнопку по АНГЛИЙСКОЙ подсказке, а харнесс
    // здесь русский. Жмём саму кнопку возврата.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(calls, greaterThanOrEqualTo(2));
    expect(
      find.textContaining('2'),
      findsOneWidget,
      reason: 'после возврата размер обновился',
    );
  });
}
