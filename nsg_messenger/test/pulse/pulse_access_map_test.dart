import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/pulse/nsg_messenger_pulse.dart';

/// **TASK79**: клиентская карта ролей — по ней экран Пульса решает, какие
/// кнопки рисовать. Семантика обязана совпадать с серверной `PulseRoles`,
/// иначе UI покажет действие, которое сервер отклонит (или спрячет то,
/// что разрешено).
void main() {
  PulseAccessEntry entry(
    String kind,
    int id,
    String role, {
    bool inherited = false,
  }) => PulseAccessEntry(
    targetKind: kind,
    targetId: id,
    role: role,
    inherited: inherited,
  );

  group('PulseClientRoles', () {
    test('порядок совпадает с серверным: owner > admin > viewer', () {
      expect(PulseClientRoles.rank('owner'), 3);
      expect(PulseClientRoles.rank('admin'), 2);
      expect(PulseClientRoles.rank('viewer'), 1);
      expect(PulseClientRoles.rank(null), 0);
    });

    test('незнакомая роль трактуется как «прав нет» (fail-closed)', () {
      // Сервер может добавить роль без пересборки клиентов; показать
      // кнопку «на всякий случай» хуже, чем не показать.
      expect(PulseClientRoles.rank('superuser'), 0);
      expect(PulseClientRoles.atLeast('superuser', 'viewer'), isFalse);
    });

    test('atLeast: старшая роль проходит, младшая — нет', () {
      expect(PulseClientRoles.atLeast('owner', 'admin'), isTrue);
      expect(PulseClientRoles.atLeast('admin', 'admin'), isTrue);
      expect(PulseClientRoles.atLeast('viewer', 'admin'), isFalse);
    });
  });

  group('PulseAccessMap', () {
    test('раскладывает роли по папкам и мониторам', () {
      final map = PulseAccessMap.fromEntries([
        entry('folder', 1, 'admin'),
        entry('monitor', 5, 'viewer'),
      ]);
      expect(map.folderRole(1), 'admin');
      expect(map.monitorRole(5), 'viewer');
      expect(map.folderAtLeast(1, 'admin'), isTrue);
      expect(map.monitorAtLeast(5, 'admin'), isFalse);
    });

    test('объект без записи — роли нет', () {
      final map = PulseAccessMap.fromEntries([entry('folder', 1, 'owner')]);
      expect(
        map.folderRole(2),
        isNull,
        reason: 'папка-путь приходит в дереве, но без роли — управления нет',
      );
      expect(
        map.monitorRole(1),
        isNull,
        reason: 'id папок и мониторов не смешиваются',
      );
      expect(map.folderRole(null), isNull);
      expect(map.monitorRole(null), isNull);
    });

    test('при дубликатах побеждает старшая роль', () {
      // Прямое членство и наследование могут прийти на один объект.
      final map = PulseAccessMap.fromEntries([
        entry('monitor', 5, 'viewer'),
        entry('monitor', 5, 'owner', inherited: true),
      ]);
      expect(map.monitorRole(5), 'owner');
    });

    test('пустая карта не даёт прав ни на что', () {
      const map = PulseAccessMap.empty();
      expect(map.folderAtLeast(1, 'viewer'), isFalse);
      expect(map.monitorAtLeast(1, 'viewer'), isFalse);
    });
  });
}
