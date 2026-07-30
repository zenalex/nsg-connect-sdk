import 'package:flutter/material.dart';

/// **Подсказка «список продолжается» (issue #74).**
///
/// Со слов пользователя: «нужно показывать внизу стрелочку, если всё меню
/// не показано сразу, т.к. если не знать, то не догадаешься о том, что
/// можно прокрутить меню». Обрезанный по высоте список выглядит ровно как
/// законченный: у модального шита нет ни рамки, ни полосы прокрутки —
/// последний видимый пункт кажется последним вообще.
///
/// Поэтому подсказка появляется ТОЛЬКО когда снизу действительно есть
/// что показать, и исчезает, когда докрутили до конца: постоянная
/// стрелка обманывала бы в другую сторону.
///
/// Обёртка вокруг прокручиваемого содержимого — сама создаёт контроллер,
/// если его не дали. Тап по стрелке прокручивает: человек, который её
/// заметил, скорее всего именно этого и хочет.
class ScrollMoreHint extends StatefulWidget {
  const ScrollMoreHint({
    super.key,
    required this.builder,
    this.stepFraction = 0.6,
  });

  /// Строит прокручиваемое содержимое с переданным контроллером.
  final Widget Function(BuildContext context, ScrollController controller)
  builder;

  /// Какую часть видимой области проматывать по тапу.
  final double stepFraction;

  @override
  State<ScrollMoreHint> createState() => _ScrollMoreHintState();
}

class _ScrollMoreHintState extends State<ScrollMoreHint> {
  final ScrollController _controller = ScrollController();
  bool _hasMore = false;

  /// Порог в пикселях: остаток меньше — считаем, что докрутили. Без него
  /// подсказка мигала бы на дробных остатках от округления высот.
  static const double _epsilon = 8;

  @override
  void initState() {
    super.initState();
    // Первое состояние известно только ПОСЛЕ раскладки: до неё
    // maxScrollExtent ещё не посчитан.
    WidgetsBinding.instance.addPostFrameCallback((_) => _recompute());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _recompute() {
    if (!mounted || !_controller.hasClients) return;
    final p = _controller.position;
    final more = p.maxScrollExtent - p.pixels > _epsilon;
    if (more != _hasMore) setState(() => _hasMore = more);
  }

  void _scrollOn() {
    if (!_controller.hasClients) return;
    final p = _controller.position;
    final step = p.viewportDimension * widget.stepFraction;
    _controller.animateTo(
      (p.pixels + step).clamp(p.minScrollExtent, p.maxScrollExtent),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NotificationListener<ScrollNotification>(
      // Ловим и метрики: содержимое шита меняется по высоте (появился
      // пункт, перерисовался пузырь), и без этого подсказка осталась бы
      // от прежней раскладки.
      onNotification: (n) {
        if (n is ScrollUpdateNotification || n is ScrollMetricsNotification) {
          _recompute();
        }
        return false;
      },
      child: Stack(
        children: [
          widget.builder(context, _controller),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: !_hasMore,
              child: AnimatedOpacity(
                opacity: _hasMore ? 1 : 0,
                duration: const Duration(milliseconds: 150),
                child: _MoreAffordance(theme: theme, onTap: _scrollOn),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoreAffordance extends StatelessWidget {
  const _MoreAffordance({required this.theme, required this.onTap});

  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surface = theme.colorScheme.surface;
    return SizedBox(
      height: 34,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Затухание: показывает, что содержимое уходит под край, а не
          // заканчивается. Прозрачный→фон — в стеклянных темах `surface`
          // сам полупрозрачен, поэтому обои под шитом остаются видны.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [surface.withValues(alpha: 0), surface],
                ),
              ),
            ),
          ),
          Semantics(
            button: true,
            label: MaterialLocalizations.of(context).moreButtonTooltip,
            child: InkResponse(
              onTap: onTap,
              radius: 18,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: 22,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
