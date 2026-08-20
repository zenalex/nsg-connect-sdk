/// **Экран здоровья доставки** (issue #120).
///
/// Экран заводится ради состояния, которое до сих пор было невидимым:
/// у продукта ноль зарегистрированных устройств при полностью готовой нашей
/// стороне. Поэтому здесь проверяется не вёрстка, а то, ЧТО он говорит.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/admin/nsg_messenger_platform_admin.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/screens/delivery_health_screen.dart';

ProductDeliveryHealth _health({
  required String key,
  required String verdict,
  int fcm = 0,
  int rustore = 0,
  int voip = 0,
  int stale = 0,
  bool hasFcm = false,
  DateTime? lastSeenAt,
  // Транспорт последней мили (#121). Поле обязательное; по умолчанию —
  // платформенные ключи, то есть поведение, которое эти тесты и проверяли
  // до его появления.
  String transport = 'platformPush',
}) => ProductDeliveryHealth(
  productExternalKey: key,
  productDisplayName: key,
  tenantExternalKey: 'nsg',
  devicesFcm: fcm,
  devicesRustore: rustore,
  devicesVoip: voip,
  staleDevices: stale,
  lastSeenAt: lastSeenAt,
  hasFcmCredentials: hasFcm,
  hasRustoreCredentials: false,
  hasVoipCredentials: false,
  verdict: verdict,
  deliveryTransport: transport,
  deliveryTransportKnown: true,
);

Future<void> _pump(
  WidgetTester t,
  Future<List<ProductDeliveryHealth>> Function() list,
) async {
  final admin = NsgMessengerPlatformAdmin.withRpcs(
    isPlatformAdminRpc: () async => true,
    listTenantsRpc: () async => const <ConnectTenantStatus>[],
    listDeliveryHealthRpc: list,
    enableAndGenerateRpc: ({required String tenantExternalKey}) =>
        throw UnimplementedError(),
    rotateSecretRpc:
        ({required String tenantExternalKey, int? graceSeconds}) =>
            throw UnimplementedError(),
    disableRpc: ({required String tenantExternalKey}) =>
        throw UnimplementedError(),
    statusRpc: ({required String tenantExternalKey}) =>
        throw UnimplementedError(),
    listAuditEventsRpc:
        ({required String tenantExternalKey, required int limit}) =>
            throw UnimplementedError(),
  );
  await t.pumpWidget(
    MaterialApp(
      localizationsDelegates: NsgL10n.localizationsDelegates,
      supportedLocales: NsgL10n.supportedLocales,
      locale: const Locale('ru'),
      home: DeliveryHealthScreen(admin: admin),
    ),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets('«ни одного устройства» названо словами, а не цветом', (t) async {
    // Ровно случай Futbolista и Титана: наша сторона готова, приложение не
    // регистрирует токены. Цвет об этом не расскажет, а строка — да.
    await _pump(
      t,
      () async => [_health(key: 'futbolista', verdict: 'noDevices')],
    );
    expect(find.textContaining('ни одного устройства'), findsOneWidget);
    expect(find.textContaining('регистраций не было'), findsOneWidget);
  });

  testWidgets('«нет ключей» отделено от «нет устройств»', (t) async {
    // Разные люди чинят: устройства — интегратор в своём приложении, ключи —
    // мы у себя. Один общий «красный» отправил бы разбираться не туда.
    await _pump(
      t,
      () async => [
        _health(key: 'titan_lk', verdict: 'noCredentials', fcm: 3),
      ],
    );
    expect(find.textContaining('нет ключей'), findsOneWidget);
    expect(find.textContaining('ключей нет'), findsOneWidget);
  });

  testWidgets('рабочий продукт показывает каналы и свежесть', (t) async {
    await _pump(
      t,
      () async => [
        _health(
          key: 'chatista',
          verdict: 'ok',
          fcm: 10,
          rustore: 1,
          voip: 4,
          hasFcm: true,
          lastSeenAt: DateTime.now().toUtc(),
        ),
      ],
    );
    expect(find.textContaining('доставка работает'), findsOneWidget);
    expect(find.textContaining('10 FCM'), findsOneWidget);
    expect(find.textContaining('FCM'), findsWidgets);
  });

  testWidgets('сбой запроса — «нет данных», а не пустая зелень', (t) async {
    // Фасад деградирует любой сбой в пустой список. Показать при этом
    // спокойный экран значило бы соврать ровно там, где признак и заводился.
    await _pump(t, () async => throw Exception('нет доступа'));
    expect(find.textContaining('Нет данных'), findsOneWidget);
  });
}
