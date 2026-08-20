/// Единственный набор эмодзи приложения — и для реакций на чужое сообщение,
/// и для вставки в своё (issue #85).
///
/// Второй, независимый список эмодзи в одном мессенджере — гарантированный
/// разъезд: смайлик, которым можно отреагировать, вдруг нельзя написать.
/// Поэтому набор и панель здесь одни, различается ровно заголовок листа.
///
/// Зависимостей нет намеренно: курированный набор по категориям (как в
/// reaction-picker-е Telegram/Slack — реакции берут из ходового набора, а не
/// из всех ~3800 Unicode-эмодзи). Полный Unicode-пикер с поиском по ключевым
/// словам — возможное расширение (часть 2 / отдельный пакет).
library;

import 'package:flutter/material.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../widgets/nsg_modal_sheet.dart';

/// **F2 часть 1** — выбор реакции на существующее сообщение. Открывается по
/// кнопке «+» в action-sheet сообщения; тап по эмодзи возвращает его через
/// `Navigator.pop`, вызывающая сторона делает `toggleReaction`.
///
/// Возвращает выбранный emoji или `null`, если лист закрыли.
Future<String?> showEmojiReactionPicker(BuildContext context) =>
    _showEmojiSheet(context, (l) => l.emojiPickerTitle);

/// **Issue #85** — выбор эмодзи для ВСТАВКИ В ТЕКСТ своего сообщения
/// (кнопка в композере). Возвращает выбранный emoji или `null` при закрытии;
/// куда его подставить, решает композер (позиция каретки, замена выделения).
///
/// Отдельная точка входа, а не флаг у [showEmojiReactionPicker], нужна только
/// ради заголовка: «Выберите реакцию» над панелью, из которой набирают текст,
/// сбивает с толку.
Future<String?> showEmojiInsertPicker(BuildContext context) =>
    _showEmojiSheet(context, (l) => l.emojiInsertPickerTitle);

Future<String?> _showEmojiSheet(
  BuildContext context,
  String Function(NsgL10n l) title,
) {
  // Issue #105: через помощник — иначе длинный набор эмодзи дорастает до
  // верха экрана и ручка уходит под вырез.
  return showNsgModalSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (_) => _EmojiPickerBody(title: title),
  );
}

/// Категория курированного набора: локализуемый ярлык-ключ + список эмодзи.
@immutable
class _EmojiCategory {
  const _EmojiCategory(this.labelKey, this.emojis);
  final String labelKey;
  final List<String> emojis;
}

/// Курированный набор ходовых реакций по категориям. Порядок — по частоте
/// использования в мессенджерах. Ярлыки категорий локализованы (см.
/// [_categoryLabel]).
const List<_EmojiCategory> _kCategories = [
  _EmojiCategory('smileys', [
    '😀',
    '😃',
    '😄',
    '😁',
    '😆',
    '😅',
    '🤣',
    '😂',
    '🙂',
    '🙃',
    '😉',
    '😊',
    '😇',
    '🥰',
    '😍',
    '🤩',
    '😘',
    '😗',
    '😚',
    '😙',
    '😋',
    '😛',
    '😜',
    '🤪',
    '😝',
    '🤗',
    '🤭',
    '🤫',
    '🤔',
    '😐',
    '😑',
    '😶',
    '😏',
    '😒',
    '🙄',
    '😬',
    '😮‍💨',
    '🤥',
    '😌',
    '😔',
    '😪',
    '🤤',
    '😴',
    '😷',
    '🤒',
    '🤕',
    '🤢',
    '🤮',
    '🥵',
    '🥶',
    '🥴',
    '😵',
    '🤯',
    '🤠',
    '🥳',
    '😎',
    '🤓',
    '🧐',
    '😕',
    '😟',
    '🙁',
    '😮',
    '😯',
    '😲',
    '😳',
    '🥺',
    '😦',
    '😧',
    '😨',
    '😰',
    '😥',
    '😢',
    '😭',
    '😱',
    '😖',
    '😣',
    '😞',
    '😓',
    '😩',
    '😫',
    '🥱',
    '😤',
    '😡',
    '😠',
    '🤬',
    '😈',
    '👿',
    '💀',
    '💩',
    '🤡',
  ]),
  _EmojiCategory('gestures', [
    '👍',
    '👎',
    '👌',
    '🤌',
    '🤏',
    '✌️',
    '🤞',
    '🤟',
    '🤘',
    '🤙',
    '👈',
    '👉',
    '👆',
    '👇',
    '☝️',
    '✋',
    '🤚',
    '🖐️',
    '🖖',
    '👋',
    '🤝',
    '🙏',
    '✍️',
    '💪',
    '👏',
    '🙌',
    '👐',
    '🤲',
    '🫶',
    '🤦',
    '🤷',
    '💅',
    '👀',
    '🧠',
    '❤️‍🔥',
  ]),
  _EmojiCategory('hearts', [
    '❤️',
    '🧡',
    '💛',
    '💚',
    '💙',
    '💜',
    '🖤',
    '🤍',
    '🤎',
    '💔',
    '❤️‍🩹',
    '💕',
    '💞',
    '💓',
    '💗',
    '💖',
    '💘',
    '💝',
    '💟',
    '💯',
    '🔥',
    '⭐',
    '🌟',
    '✨',
    '⚡',
    '💥',
    '💫',
    '🎉',
    '🎊',
    '🏆',
  ]),
  _EmojiCategory('animals', [
    '🐶',
    '🐱',
    '🐭',
    '🐹',
    '🐰',
    '🦊',
    '🐻',
    '🐼',
    '🐨',
    '🐯',
    '🦁',
    '🐮',
    '🐷',
    '🐸',
    '🐵',
    '🐔',
    '🐧',
    '🐦',
    '🦄',
    '🐝',
    '🦋',
    '🐢',
    '🐙',
    '🐬',
    '🐳',
    '🦕',
    '🐾',
  ]),
  _EmojiCategory('food', [
    '🍏',
    '🍎',
    '🍐',
    '🍊',
    '🍋',
    '🍌',
    '🍉',
    '🍇',
    '🍓',
    '🫐',
    '🍒',
    '🍑',
    '🥭',
    '🍍',
    '🥥',
    '🥝',
    '🍅',
    '🍆',
    '🥑',
    '🌶️',
    '🌽',
    '🥕',
    '🍔',
    '🍟',
    '🍕',
    '🌭',
    '🥪',
    '🌮',
    '🍿',
    '🍩',
    '🍪',
    '🎂',
    '🍰',
    '🍫',
    '🍬',
    '🍭',
    '☕',
    '🍺',
    '🍻',
    '🥂',
    '🍷',
    '🥃',
    '🍾',
  ]),
  _EmojiCategory('activity', [
    '⚽',
    '🏀',
    '🏈',
    '⚾',
    '🎾',
    '🏐',
    '🏓',
    '🏸',
    '🥅',
    '⛳',
    '🎯',
    '🎮',
    '🎲',
    '🎸',
    '🎹',
    '🎺',
    '🎻',
    '🥁',
    '🎤',
    '🎧',
    '🎬',
    '🎨',
    '♟️',
    '🚀',
    '✈️',
    '🚗',
    '🏆',
    '🥇',
    '🎖️',
    '🏅',
  ]),
  _EmojiCategory('symbols', [
    '✅',
    '❌',
    '⭕',
    '❗',
    '❓',
    '‼️',
    '⁉️',
    '💤',
    '💢',
    '💬',
    '👋',
    '🆗',
    '🆒',
    '🔝',
    '🎁',
    '🔔',
    '📌',
    '📍',
    '🔒',
    '🔑',
    '💡',
    '🔥',
    '⚠️',
    '♻️',
    '☑️',
    '🚫',
    '💰',
    '🕐',
    '📢',
    '🌈',
  ]),
];

String _categoryLabel(NsgL10n l, String key) => switch (key) {
  'smileys' => l.emojiCategorySmileys,
  'gestures' => l.emojiCategoryGestures,
  'hearts' => l.emojiCategoryHearts,
  'animals' => l.emojiCategoryAnimals,
  'food' => l.emojiCategoryFood,
  'activity' => l.emojiCategoryActivity,
  'symbols' => l.emojiCategorySymbols,
  _ => key,
};

class _EmojiPickerBody extends StatelessWidget {
  const _EmojiPickerBody({required this.title});

  /// Заголовок листа. Резолвим из [NsgL10n] уже внутри build-а: на момент
  /// вызова `showModalBottomSheet` локализации ещё берутся из контекста
  /// вызывающей стороны, а лист живёт в другом поддереве.
  final String Function(NsgL10n l) title;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.6;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                title(l),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: CustomScrollView(
                slivers: [
                  for (final cat in _kCategories) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _categoryLabel(l, cat.labelKey),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 48,
                              mainAxisSpacing: 2,
                              crossAxisSpacing: 2,
                            ),
                        delegate: SliverChildBuilderDelegate((ctx, i) {
                          final emoji = cat.emojis[i];
                          return InkResponse(
                            onTap: () => Navigator.of(ctx).pop(emoji),
                            radius: 22,
                            child: Center(
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 26),
                              ),
                            ),
                          );
                        }, childCount: cat.emojis.length),
                      ),
                    ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
