// Issue #86 — «пуш-токен не взялся, приложение молчит».
//
// Здесь проверяется единственное, что провайдеру нужно решить в этот
// момент: НЕ «есть токен или нет», а ПОЧЕМУ его нет. Причины лечатся
// разным (разрешение против сети/entitlements), и совет не по адресу
// хуже молчания — поэтому каждая комбинация зафиксирована отдельно.

import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_messenger/nsg_messenger.dart';
import 'package:nsg_messenger_push/nsg_messenger_push.dart';

void main() {
  test('разрешение выдано + токен есть → ready', () {
    expect(
      resolvePushTokenStatus(permissionGranted: true, token: 'dSOhEe...VBQs'),
      PushTokenStatus.ready,
    );
  });

  test('разрешение выдано, токена нет → tokenUnavailable (случай issue #86: '
      'APNs-токен не доехал за 30 секунд)', () {
    expect(
      resolvePushTokenStatus(permissionGranted: true, token: null),
      PushTokenStatus.tokenUnavailable,
      reason: 'советовать «разрешите уведомления» тут нельзя — уже разрешены',
    );
  });

  test('пустая строка токена — это тоже отсутствие токена (RuStore-путь)', () {
    expect(
      resolvePushTokenStatus(permissionGranted: true, token: ''),
      PushTokenStatus.tokenUnavailable,
    );
  });

  test('разрешения нет → permissionDenied', () {
    expect(
      resolvePushTokenStatus(permissionGranted: false, token: null),
      PushTokenStatus.permissionDenied,
    );
  });

  test('разрешения нет, но токен выдан (Android 13+ без POST_NOTIFICATIONS) → '
      'permissionDenied: токен валиден, а уведомления система не покажет', () {
    expect(
      resolvePushTokenStatus(permissionGranted: false, token: 'tok-android'),
      PushTokenStatus.permissionDenied,
    );
  });

  test('isBroken: молчим, пока чинить нечего или вердикта ещё нет', () {
    expect(PushTokenStatus.ready.isBroken, isFalse);
    expect(PushTokenStatus.pending.isBroken, isFalse);
    expect(PushTokenStatus.unsupported.isBroken, isFalse);
    expect(PushTokenStatus.permissionDenied.isBroken, isTrue);
    expect(PushTokenStatus.tokenUnavailable.isBroken, isTrue);
  });
}
