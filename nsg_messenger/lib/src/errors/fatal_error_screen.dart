/// **Экран смертельной ошибки** — issue #134.
///
/// **Что было.** Приложение падало при построении первого кадра, и человек
/// видел серый прямоугольник без единого слова: ни надписи, ни кнопки, ни
/// намёка на отказ. Выглядело как «ещё грузится». Телеметрия при этом
/// сработала — события дошли в GlitchTip, — то есть отказ был тихим не для
/// нас, а для пользователя. Это разные беды, и вторая здесь.
///
/// Серый прямоугольник — умолчание Flutter: в debug он рисует красный экран
/// со стеком, в release намеренно не рисует ничего, потому что показывать
/// стек человеку нельзя. Но подставлять вместо стека НИЧЕГО — это решение
/// по умолчанию, а не наше.
///
/// **Главное требование — самодостаточность.** Виджет обязан работать без
/// `Localizations`, без `Theme`, без наших контроллеров и без `MaterialApp`
/// над собой. Причина простая: сегодняшний отказ и БЫЛ отказом локализации
/// (issue #133 — строки читались выше `Localizations`). Виджет, берущий
/// оттуда надписи, показал бы второй серый экран поверх первого — ровно там,
/// где он нужнее всего.
///
/// Отсюда все решения ниже, которые иначе выглядели бы странно: свои цвета
/// вместо темы, `Directionality` руками, никаких `Material`-кнопок (им
/// нужен `Material` в предках и `MaterialLocalizations` для части поведения),
/// строки параметрами со значениями по умолчанию вместо ARB.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Подписи экрана. Параметрами, а не из ARB: см. требование
/// самодостаточности в docstring библиотеки.
class NsgFatalErrorStrings {
  const NsgFatalErrorStrings({
    this.title = 'Приложение не смогло запуститься',
    this.reload = 'Перезагрузить',
    this.copy = 'Скопировать подробности',
    this.copied = 'Скопировано',
  });

  final String title;
  final String reload;
  final String copy;
  final String copied;
}

/// Короткая строка о причине — **без стека**.
///
/// Стек человеку показывать нельзя (его и прятали, отключая красный экран),
/// а вот тип ошибки в отчёте от человека бесценен: «серый экран» и
/// «`NoSuchMethodError` при запуске» — это две разные заявки, и вторая
/// решается сразу.
///
/// Чистая: то, что попадёт человеку на глаза, должно проверяться без
/// построения виджета.
String fatalErrorSummary(FlutterErrorDetails details) {
  final ex = details.exception;
  final type = ex.runtimeType.toString();
  final text = ex.toString();
  // Сообщение исключения нередко само содержит тип — не удваиваем.
  if (text.startsWith(type)) {
    return _firstLine(text);
  }
  return '$type: ${_firstLine(text)}';
}

/// Полные подробности для буфера обмена: тип, сообщение и место — то, чего
/// не хватало в заявках вида «серый экран».
String fatalErrorClipboardText(FlutterErrorDetails details) {
  final buffer = StringBuffer()..writeln(fatalErrorSummary(details));
  final library = details.library;
  if (library != null && library.trim().isNotEmpty) {
    buffer.writeln('где: $library');
  }
  final stack = details.stack;
  if (stack != null) {
    // В буфер стек класть можно: человек копирует его НАМ, это не то же
    // самое, что показывать его на экране.
    buffer.writeln('---');
    buffer.write(stack.toString().split('\n').take(20).join('\n'));
  }
  return buffer.toString();
}

String _firstLine(String s) {
  final i = s.indexOf('\n');
  final line = i < 0 ? s : s.substring(0, i);
  return line.length > 200 ? '${line.substring(0, 199)}…' : line;
}

/// Экран смертельной ошибки. Строится из примитивов `widgets.dart` —
/// никаких зависимостей от темы, локализации и Material.
class NsgFatalErrorScreen extends StatefulWidget {
  const NsgFatalErrorScreen({
    super.key,
    required this.details,
    this.onReload,
    this.strings = const NsgFatalErrorStrings(),
  });

  final FlutterErrorDetails details;

  /// Чем перезагружать. На вебе это `window.location.reload()`, но
  /// `dart:html` в SDK не тянем — способ знает host-app и передаёт сюда.
  /// `null` — кнопки перезагрузки не будет: кнопка, которая ничего не
  /// делает, хуже её отсутствия.
  final VoidCallback? onReload;

  final NsgFatalErrorStrings strings;

  @override
  State<NsgFatalErrorScreen> createState() => _NsgFatalErrorScreenState();
}

class _NsgFatalErrorScreenState extends State<NsgFatalErrorScreen> {
  bool _copied = false;

  @override
  Widget build(BuildContext context) {
    // **issue #145**: пока строимся, повторный вызов `ErrorWidget.builder`
    // обязан вернуть лист — иначе отказ внутри этого построения уводит в
    // бесконечную рекурсию (см. доку у `_buildingFatalScreen`).
    _buildingFatalScreen = true;
    try {
      return _build(context);
    } finally {
      _buildingFatalScreen = false;
    }
  }

  Widget _build(BuildContext context) {
    const fg = Color(0xFF1A1A1A);
    const muted = Color(0xFF6B6B6B);
    const bg = Color(0xFFF6F6F6);

    return Directionality(
      // Руками: `Directionality` может не быть в предках, а без него
      // падает даже `Text` — то есть аварийный экран уронил бы сам себя.
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: bg,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.strings.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: fg,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  fatalErrorSummary(widget.details),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: muted,
                    fontSize: 13,
                    decoration: TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 24),
                if (widget.onReload != null) ...[
                  _Button(
                    label: widget.strings.reload,
                    onTap: widget.onReload!,
                  ),
                  const SizedBox(height: 8),
                ],
                _Button(
                  label: _copied ? widget.strings.copied : widget.strings.copy,
                  onTap: _copy,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copy() async {
    await Clipboard.setData(
      ClipboardData(text: fatalErrorClipboardText(widget.details)),
    );
    if (mounted) setState(() => _copied = true);
  }
}

/// Кнопка на примитивах: `Material`-кнопкам нужен `Material` в предках, а
/// его здесь может не быть — как и всего остального.
class _Button extends StatelessWidget {
  const _Button({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE3E3E3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 14,
            decoration: TextDecoration.none,
          ),
        ),
      ),
    );
  }
}

/// Поставить наш аварийный экран вместо серого прямоугольника.
///
/// Зовётся из `main()` host-app до `runApp`. В debug по умолчанию НЕ
/// подменяем: там красный экран Flutter со стеком полезнее — он для
/// разработчика, а наш для человека.
/// **Сторож повторного входа** — issue #145.
///
/// Первая редакция этого файла подвесила Windows-сборку намертво, и разбор
/// дампа занял два дня, поэтому механизм описан подробно.
///
/// `ErrorWidget.builder` вызывается ИЗ `inflateWidget`, когда построение
/// виджета бросило. Наш экран — не лист: это `Directionality` → `ColoredBox`
/// → `Center` → `Padding` → `Column` → тексты и кнопки. Каждый уровень
/// требует стека. Если ошибка случилась уже на глубине, построение экрана
/// доедает остаток и бросает `StackOverflowError`, его снова ловит
/// `inflateWidget`, снова зовёт нас — и так вечно:
///
/// ```
/// inflateWidget → _reportException → ErrorWidget.builder → наш экран
///   → StackOverflowError → inflateWidget → ErrorWidget.builder → …
/// ```
///
/// В дампе это выглядело как 21 456 кадров Dart, стек съеден на 899,7 КБ из
/// 904 и повторяющийся блок ровно в 21 кадр. Штатный `ErrorWidget` так не
/// умеет: он лист (`RenderErrorBox`), рекурсировать нечем — потому и в debug
/// беды нет, там наш экран не ставится.
///
/// Сторож разрывает цикл: пока строится наш экран, повторный вызов отдаёт
/// заведомо безопасный лист. Красивого сообщения человек в этом случае не
/// увидит — но увидит хоть что-то, вместо занятого ядра и мёртвого окна.
bool _buildingFatalScreen = false;

/// Сколько раз подряд разрешаем построить экран, прежде чем перейти на лист.
///
/// Одного сторожа мало: ошибки могут идти не вложенно, а подряд — по одной на
/// соседний виджет. Тогда вложенности нет, а работа всё та же.
const int _maxFatalScreensInRow = 3;
int _fatalScreensInRow = 0;

/// Заведомо безопасная замена: лист, который не может ни бросить, ни уйти в
/// рекурсию. Ровно та роль, что у штатного `RenderErrorBox`.
class _MinimalErrorLeaf extends LeafRenderObjectWidget {
  const _MinimalErrorLeaf();

  @override
  RenderObject createRenderObject(BuildContext context) => RenderErrorBox();
}

/// Поставить наш аварийный экран вместо серого прямоугольника.
///
/// Зовётся из `main()` host-app до `runApp`. В debug по умолчанию НЕ
/// подменяем: там красный экран Flutter со стеком полезнее — он для
/// разработчика, а наш для человека.
void installNsgErrorWidget({
  VoidCallback? onReload,
  NsgFatalErrorStrings strings = const NsgFatalErrorStrings(),
  bool alsoInDebug = false,
}) {
  if (!kReleaseMode && !alsoInDebug) return;
  ErrorWidget.builder = (details) {
    // **issue #145.** Повторный вход или слишком много подряд — отдаём лист.
    if (_buildingFatalScreen || _fatalScreensInRow >= _maxFatalScreensInRow) {
      return const _MinimalErrorLeaf();
    }
    _fatalScreensInRow++;
    return NsgFatalErrorScreen(
      details: details,
      onReload: onReload,
      strings: strings,
    );
  };
}

/// Сбросить счётчик подряд идущих аварийных экранов.
///
/// Зовётся, когда кадр построился благополучно: иначе три давних ошибки за
/// всю сессию навсегда лишили бы человека внятного экрана.
/// Пометить, что экран сейчас строится. Только для тестов: настоящий флаг
/// живёт ровно на время `build`, и подстроить это снаружи иначе нечем —
/// нужен отказ ВНУТРИ построения, а дерево экрана фиксировано.
@visibleForTesting
// ignore: avoid_positional_boolean_parameters
void debugSetFatalScreenBuilding(bool value) => _buildingFatalScreen = value;

@visibleForTesting
void resetFatalScreenGuard() {
  _fatalScreensInRow = 0;
  _buildingFatalScreen = false;
}
