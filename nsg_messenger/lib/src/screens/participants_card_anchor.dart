/// Состав группы прямо в переписке — по ТАПУ на подпись «N участников» в
/// шапке чата.
///
/// **issue #63** сделал это по наведению мыши. **issue #91** отменил:
/// «Список участников чата отображается сразу при наведении мышки. Страшно
/// бесит. Давай только по тапу сделаем». Претензия справедливая: карточка
/// выскакивала, когда курсор просто проходил мимо по дороге к другой
/// кнопке, — то есть в большинстве случаев её никто не звал.
///
/// Тап заодно уравнял платформы: раньше на телефоне состава здесь не было
/// вовсе (наведения там не существует), и способ был только через настройки
/// группы. Теперь один жест работает везде.
///
/// Подпись живёт ВНУТРИ шапки, у которой свой тап (настройки группы). Это не
/// конфликт: внутренний жест выигрывает арену в своих границах, поэтому тап
/// по подписи открывает состав, а тап рядом — по-прежнему настройки.
///
/// **Список в `RoomDetails` обрезан сервером** (`participantsPreviewSize`
/// = 30), а `totalParticipants` — настоящее число. Поэтому в карточке
/// честная строка «и ещё N»: молча показать 30 из 200 хуже, чем не
/// показать ничего — пользователь пересчитает и решит, что список врёт.
library;

import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../theme/overlay_surface.dart';
import '../widgets/nsg_bot_badge.dart';

/// Обёртка-якорь: показывает [child], а по тапу — карточку состава.
class ParticipantsCardAnchor extends StatefulWidget {
  const ParticipantsCardAnchor({
    super.key,
    required this.child,
    required this.participants,
    required this.totalParticipants,
  });

  final Widget child;

  /// Превью состава с сервера (может быть короче [totalParticipants]).
  final List<RoomParticipant> participants;

  /// Настоящее число участников комнаты.
  final int totalParticipants;

  @override
  State<ParticipantsCardAnchor> createState() => _ParticipantsCardAnchorState();
}

class _ParticipantsCardAnchorState extends State<ParticipantsCardAnchor> {
  final _link = LayerLink();
  final _controller = OverlayPortalController();

  /// Закрытия здесь нет намеренно: пока карточка открыта, весь экран
  /// перекрыт барьером (см. `overlayChildBuilder`), и до подписи тап уже не
  /// доходит — закрывает барьер. Ветка `if (isShowing) hide()` была бы
  /// недостижимой, а тест на неё — зелёным по неверной причине: он и вправду
  /// сначала прошёл, потому что второй тап уходил в барьер.
  void _open() {
    if (!_controller.isShowing) _controller.show();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.participants.isEmpty) return widget.child;
    return CompositedTransformTarget(
      link: _link,
      child: OverlayPortal(
        controller: _controller,
        overlayChildBuilder: (context) => Stack(
          children: [
            // Тап мимо карточки закрывает её. Барьер прозрачный и на весь
            // экран: без него карточка висела бы, пока человек не попадёт
            // повторно ровно в подпись, — а закрывать хочется где угодно.
            Positioned.fill(
              child: GestureDetector(
                key: const Key('participantsCardBarrier'),
                behavior: HitTestBehavior.opaque,
                onTap: _controller.hide,
              ),
            ),
            Positioned(
              // **Боевой тест, задача C1**: без `left`/`top` карточка
              // разворачивалась во весь экран и накрывала переписку.
              //
              // `Positioned` со ВСЕМИ null-полями не считается позиционированным
              // (`StackParentData.isPositioned` смотрит именно на left/top/right/
              // bottom/width/height), поэтому Overlay кладёт такого ребёнка как
              // обычного и выдаёт ему ТУГИЕ constraints размером с экран. Дальше
              // они проходят насквозь через `CompositedTransformFollower` и
              // `MouseRegion` (оба — прокси), а `ConstrainedBox` внутри карточки
              // свои 220..300×320 не отстаивает: он делает
              // `additional.enforce(incoming)`, и на тугих входных constraints
              // результат остаётся тугим во весь экран.
              //
              // Достаточно задать хоть одну координату: ребёнок становится
              // позиционированным, и `RenderStack.layoutPositionedChild` выдаёт
              // ему НЕОГРАНИЧЕННЫЕ constraints — карточка меряется по своему
              // содержимому, а на место её всё равно уводит слой follower'а.
              // Тот же приём уже стоит в оверлее подсказок композера
              // (`message_composer.dart`, `_insertTypeaheadOverlay`).
              left: 0,
              top: 0,
              child: CompositedTransformFollower(
                link: _link,
                targetAnchor: Alignment.bottomLeft,
                followerAnchor: Alignment.topLeft,
                offset: const Offset(0, 6),
                child: _ParticipantsCard(
                  participants: widget.participants,
                  totalParticipants: widget.totalParticipants,
                ),
              ),
            ),
          ],
        ),
        child: GestureDetector(
          // opaque: подпись — это текст, и без непрозрачного поведения тап
          // мимо глифов проваливался бы наружу, в шапку, открывая настройки.
          behavior: HitTestBehavior.opaque,
          onTap: _open,
          child: MouseRegion(
            // Курсор-палец: подпись стала кликабельной, и это должно быть
            // видно до нажатия, а не выясняться экспериментом.
            cursor: SystemMouseCursors.click,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _ParticipantsCard extends StatelessWidget {
  const _ParticipantsCard({
    required this.participants,
    required this.totalParticipants,
  });

  final List<RoomParticipant> participants;
  final int totalParticipants;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);
    final hidden = totalParticipants - participants.length;
    return Material(
      elevation: 8,
      // **issue #82**: без явного цвета `Material` берёт `canvasColor`, а в
      // glass-темах он прозрачный — сквозь карточку читалась переписка под
      // ней («каша» со слов пользователя). Карточка ВСПЛЫВАЕТ над
      // контентом, значит ей полагается тот же фон, что меню и диалогам
      // (issue #43); она появилась позже того фикса и под него не попала.
      color: kOverlaySurface,
      // Карточка всплывает над лентой такого же тёмного тона, а тень от
      // elevation на тёмном фоне почти не читается — границ панели не
      // видно, и состав выглядит как текст, напечатанный поверх чата
      // («почти не выделяющийся список» из отчёта с боевого теста).
      // Волосяная линия по контуру довершает отрыв от фона.
      //
      // Цвет границы — фиксированный светлый, а НЕ из темы: фон карточки
      // это всегда тёмный [kOverlayBaseInk] независимо от темы хоста, и
      // `onSurface` светлой темы дал бы тёмное по тёмному, то есть ту же
      // невидимую границу.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 220,
          maxWidth: 300,
          maxHeight: 320,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: participants.length,
                itemBuilder: (context, i) {
                  final p = participants[i];
                  final name = (p.displayName ?? '').trim().isNotEmpty
                      ? p.displayName!.trim()
                      : p.matrixUserId;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                        if (NsgBotBadge.isNonHuman(p.participantKind)) ...[
                          const SizedBox(width: 6),
                          NsgBotBadge(kind: p.participantKind, compact: true),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            if (hidden > 0) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    l.participantsHoverMore(hidden),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
