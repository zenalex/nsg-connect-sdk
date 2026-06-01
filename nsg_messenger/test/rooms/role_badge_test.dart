import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/rooms/role_badge.dart';

import '../test_helpers.dart';

/// **TASK29 Chunk 2**: tests для [RoleBadge] — owner/admin/member icons.
void main() {
  testWidgets('member → SizedBox.shrink (no icon)', (tester) async {
    await tester.pumpWidget(
      wrapL10n(const RoleBadge(role: RoomMemberRole.member)),
    );
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('admin → shield icon visible с tooltip', (tester) async {
    await tester.pumpWidget(
      wrapL10n(const RoleBadge(role: RoomMemberRole.admin)),
    );
    expect(find.byIcon(Icons.shield_outlined), findsOneWidget);
    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, 'Admin');
  });

  testWidgets('owner → crown icon visible с tooltip', (tester) async {
    await tester.pumpWidget(
      wrapL10n(const RoleBadge(role: RoomMemberRole.owner)),
    );
    expect(find.byIcon(Icons.workspace_premium), findsOneWidget);
    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, 'Owner');
  });

  testWidgets('RU локаль — RU-текст в tooltip', (tester) async {
    await tester.pumpWidget(
      wrapL10n(
        const RoleBadge(role: RoomMemberRole.owner),
        locale: const Locale('ru'),
      ),
    );
    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.message, 'Владелец');
  });
}
