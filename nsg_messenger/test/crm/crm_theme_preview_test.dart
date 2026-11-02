import 'package:nsg_messenger/src/crm/crm_components.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';
import 'package:nsg_messenger/src/crm/crm_detail_screen.dart';
import 'package:nsg_messenger/src/crm/crm_forms.dart';
import 'package:nsg_messenger/src/crm/crm_rpc.dart';
import 'package:nsg_messenger/src/crm/crm_screen.dart';
import 'package:nsg_messenger/src/crm/crm_state.dart';
import 'package:nsg_messenger/src/crm/crm_controller.dart';
import 'package:nsg_messenger/src/theme/chatista_theme.dart';
import 'package:nsg_messenger/src/widgets/glass_background.dart';
import 'package:nsg_messenger/src/i18n/generated/nsg_l10n.dart';
import 'package:nsg_messenger/src/crm/crm_proposal_card.dart';
import 'crm_screens_test.dart' as fixture;

class PreviewEndpoint extends fixture.FakeCrm {
  @override
  dynamic noSuchMethod(Invocation i) {
    if (i.memberName == #getDeal) return Future.value(deals.first);
    if (i.memberName == #getContext) return Future.value('[]');
    if (i.memberName == #listPipelines) {
      return Future.value(
        '{"pipelines":[{"id":1,"name":"Партнёрство","stages":[{"id":1,"name":"Контакт","kind":"open","sortOrder":1},{"id":2,"name":"Встреча","kind":"open","sortOrder":2},{"id":3,"name":"Пилот","kind":"open","sortOrder":3},{"id":4,"name":"Подключён","kind":"open","sortOrder":4},{"id":5,"name":"Активен","kind":"open","sortOrder":5},{"id":6,"name":"Выигрыш","kind":"won","sortOrder":6},{"id":7,"name":"Отказ","kind":"lost","sortOrder":7}]}]}',
      );
    }
    if (i.memberName == #getCompany) {
      return Future.value(
        CrmCompanyDetails(
          company: previewCompany(),
          deals: deals.take(1).toList(),
          contacts: deals.first.contacts,
          activities: deals.first.activities,
          documents: [],
        ),
      );
    }
    return super.noSuchMethod(i);
  }
}

CrmCompanyView previewCompany() => CrmCompanyView(
  id: 1,
  spaceId: 1,
  segmentId: 1,
  version: 1,
  name: 'Тестовая лига',
  kind: CrmCompanyKind.organizer,
  ownerUserId: 7,
  tags: [],
  status: CrmCompanyStatus.active,
);
const previewSpace = CrmSpaceInfo(1, 'Команда', 'UTC', 'RUB', false, [
  CrmSegmentInfo(1, 'Сегмент A', 'crm_manager', true, true),
], 77);

void main() {
  final export = Platform.environment['CRM_SCREENSHOTS'];
  final palettes = [
    ('sunset', GlassPalette.sunset, ChatistaTheme.glassSunset()),
    ('oceanic', GlassPalette.oceanic, ChatistaTheme.glassOceanic()),
    ('aurora', GlassPalette.aurora, ChatistaTheme.glassAurora()),
    ('ember', GlassPalette.ember, ChatistaTheme.glassEmber()),
    ('light', GlassPalette.sunset, ChatistaTheme.crema()),
  ];
  for (final (name, palette, theme) in palettes) {
    for (final desktop in [false, true]) {
      testWidgets(
        '$name ${desktop ? 'desktop' : 'phone'}: screens fit and use theme tokens',
        (t) async {
          t.view.physicalSize = desktop
              ? const Size(1440, 900)
              : const Size(390, 844);
          t.view.devicePixelRatio = 1;
          addTearDown(t.view.resetPhysicalSize);
          addTearDown(t.view.resetDevicePixelRatio);
          addTearDown(t.view.resetViewInsets);
          if (export != null && Platform.isWindows) {
            final loader = FontLoader('CrmPreview')
              ..addFont(
                Future.value(
                  ByteData.sublistView(
                    File(
                      '${Platform.environment['WINDIR'] ?? 'C:/Windows'}/Fonts/arial.ttf',
                    ).readAsBytesSync(),
                  ),
                ),
              );
            await loader.load();
            final serif = FontLoader('serif')
              ..addFont(
                Future.value(
                  ByteData.sublistView(
                    File(
                      '${Platform.environment['WINDIR'] ?? 'C:/Windows'}/Fonts/georgiai.ttf',
                    ).readAsBytesSync(),
                  ),
                ),
              );
            await serif.load();
            var sdk = File(Platform.resolvedExecutable).parent;
            while (!File(
              '${sdk.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
            ).existsSync()) {
              if (sdk.parent.path == sdk.path) {
                throw StateError('Flutter font assets not found');
              }
              sdk = sdk.parent;
            }
            final icons = FontLoader('MaterialIcons')
              ..addFont(
                Future.value(
                  ByteData.sublistView(
                    File(
                      '${sdk.path}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
                    ).readAsBytesSync(),
                  ),
                ),
              );
            await icons.load();
          }
          final endpoint = PreviewEndpoint()
            ..deals = [
              fixture.deal().copyWith(
                company: previewCompany(),
                title: 'Трансляции и пресс-служба',
                ownerDisplayName: 'Тестовый менеджер',
                nextStepAssigneeDisplayName: 'Тестовый менеджер',
                contacts: [
                  CrmContactView(
                    id: 1,
                    segmentId: 1,
                    version: 1,
                    pdRedacted: true,
                  ),
                ],
                documents: [
                  CrmDocumentView(
                    id: 1,
                    segmentId: 1,
                    version: 1,
                    kind: CrmDocumentKind.other,
                    title: 'Тестовый план пилота',
                    url: 'https://example.test/plan',
                  ),
                ],
                activities: [
                  CrmActivityView(
                    id: 1,
                    segmentId: 1,
                    version: 1,
                    type: CrmActivityType.meeting,
                    occurredAt: DateTime.now().subtract(
                      const Duration(days: 1),
                    ),
                    summary: 'Обсудили тестовый пилот',
                    sourceJson: '{}',
                    authorUserId: 7,
                    authorDisplayName: 'Тестовый менеджер',
                    actorKind: CrmActorKind.user,
                  ),
                  CrmActivityView(
                    id: 2,
                    segmentId: 1,
                    version: 1,
                    type: CrmActivityType.note,
                    occurredAt: DateTime.now(),
                    summary: 'Подготовлен следующий шаг',
                    sourceJson: '{}',
                    authorUserId: 7,
                    onBehalfOfUserId: 7,
                    onBehalfOfDisplayName: 'Тестовый менеджер',
                    actorKind: CrmActorKind.agent,
                  ),
                ],
              ),
            ];
          final template = endpoint.deals.first;
          endpoint.deals.addAll([
            for (var i = 2; i <= 8; i++)
              template.copyWith(
                id: i,
                stageId: (i - 1) % 5 + 1,
                title: [
                  'Табло и пакеты',
                  'Региональный этап',
                  'Ссылки команд',
                  'Покрытие состава',
                  'Пакет графики',
                  'Материалы партнёру',
                  'Участие в форуме',
                ][i - 2],
                amount: '${i * 12500}.50',
                nextStep: [
                  'Прислать предложение',
                  'Встреча с руководством',
                  'Список участников',
                ][i % 3],
                nextStepAt: DateTime.now().add(
                  Duration(days: i % 3 == 0 ? -1 : i % 2, hours: 2),
                ),
                company: previewCompany().copyWith(
                  id: i,
                  name: 'Тестовая команда $i',
                ),
              ),
          ]);
          final rpc = CrmRpc(endpoint, authRetry: false);
          final controller = CrmController(rpc: rpc, spaceId: 1, userId: 7);
          final key = GlobalKey();
          Widget host(Widget child) => RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              locale: const Locale('ru'),
              localizationsDelegates: NsgL10n.localizationsDelegates,
              supportedLocales: NsgL10n.supportedLocales,
              theme: theme.applyTo(
                ThemeData(
                  useMaterial3: true,
                  fontFamily: export == null ? null : 'CrmPreview',
                ),
              ),
              home: Stack(
                children: [
                  if (name == 'light')
                    Positioned.fill(
                      child: ColoredBox(color: theme.colorScheme!.surface),
                    ),
                  if (name != 'light') GlassBackground(palette: palette),
                  Positioned.fill(child: child),
                ],
              ),
            ),
          );
          Future<void> capture(String screen) async {
            expect(t.takeException(), isNull);
            expect(find.byType(ChoiceChip), findsNothing);
            expect(find.byType(FilterChip), findsNothing);
            expect(find.byType(DropdownButton<int>), findsNothing);
            expect(find.byType(ExpansionTile), findsNothing);
            expect(find.byType(ListTile), findsNothing);
            if (export == null || (name != 'sunset' && name != 'light')) return;
            await t.runAsync(() async {
              final image =
                  await (key.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final file = File(
                '$export/$name-$screen-${desktop ? 'desktop' : 'phone'}.png',
              );
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }

          await t.pumpWidget(
            host(
              CrmScreen(rpc: rpc, controller: controller, space: previewSpace),
            ),
          );
          await t.pumpAndSettle();
          await capture('steps');
          await t.tap(find.text('Воронка'));
          await t.pumpAndSettle();
          await capture('pipeline');
          if (!desktop) t.view.physicalSize = const Size(390, 1420);
          await t.pumpWidget(
            host(
              CrmDealScreen(
                id: 1,
                rpc: rpc,
                space: previewSpace,
                controller: controller,
              ),
            ),
          );
          await t.pumpAndSettle();
          await capture('deal');
          if (!desktop) t.view.physicalSize = const Size(390, 1100);
          await t.pumpWidget(
            host(CrmCompanyScreen(id: 1, rpc: rpc, space: previewSpace)),
          );
          await t.pumpAndSettle();
          await capture('company');
          if (!desktop) t.view.physicalSize = const Size(390, 844);
          await t.pumpWidget(
            host(
              Scaffold(
                backgroundColor: Colors.transparent,
                body: Builder(
                  builder: (context) => GestureDetector(
                    key: const ValueKey('crm-preview-open-touch'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => crmQuickActivity(
                      context,
                      controller,
                      endpoint.deals.first,
                      agentRoomId: previewSpace.agentRoomId,
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          );
          await t.tap(find.byKey(const ValueKey('crm-preview-open-touch')));
          await t.pumpAndSettle();
          await capture('quick-touch');
          expect(find.text('Добавить касание'), findsNothing);
          if (!desktop) {
            // Synthetic keyboard inset; no OS keyboard is drawn in this preview.
            t.view.viewInsets = const FakeViewPadding(bottom: 300);
            await t.pumpAndSettle();
            await t.ensureVisible(
              find.byKey(const ValueKey('crm-activity-due')),
            );
            await t.pumpAndSettle();
            await capture('quick-touch-keyboard');
            t.view.resetViewInsets();
            await t.pumpAndSettle();
          }
          Navigator.of(
            t.element(find.byKey(const ValueKey('crm-preview-open-touch'))),
          ).pop();
          await t.pumpAndSettle();
          await t.pumpWidget(
            host(
              Scaffold(
                backgroundColor: Colors.transparent,

                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const CrmAgentHeader(
                        title: 'Агент CRM',
                        subtitle: 'только вы и агент · ваши права',
                      ),
                      const SizedBox(height: 14),
                      CrmProposalCard(
                        proposalId: 1,
                        body:
                            'Предлагаю обновить сделку «Пилот».\nСледующий шаг: Встреча → Запустить тестовый пилот.\nЭтап: Диалог → Пилот.\nОтветьте «да» на эту карточку для подтверждения.',
                        eventId: r'$proposal-test',
                        readStatus: (_) async => {
                          'status': 'proposed',
                          'expiresAt': DateTime.now()
                              .add(const Duration(minutes: 30))
                              .toUtc()
                              .toIso8601String(),
                        },
                        reply: (_, text) async {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          await t.pumpAndSettle();
          await capture('agent-proposal');
          await t.pumpWidget(const SizedBox());
          controller.dispose();
        },
      );
    }
  }
}
