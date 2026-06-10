import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart'
    show RoomParticipant;

import '../i18n/generated/nsg_l10n.dart';
import '../theme/nsg_messenger_theme.dart';
import '../utils/relative_time.dart';
import 'attachments/attachment_bubble.dart';
import 'attachments/mxc_image_provider.dart';
import '../widgets/nsg_avatar_image.dart';
import 'chat_message.dart';
import 'markdown_spans.dart';

/// Рендер одного [ChatMessage] в чате (TASK15 Chunk 2).
///
/// Layout:
///   * own bubble справа (primary container);
///   * peer bubble слева (surface variant);
///   * timestamp (timeago short form) под сообщением;
///   * status icon у own (pending/sent/failed);
///   * на failed — tap по retry-button зовёт [onRetry].
///
/// Avatar / display name peer-а на TASK15 не отображаются — это
/// требует знание [RoomDetails.participants], которые ChatScreen
/// уже подгружает; на MVP достаточно left/right выравнивания. Avatars
/// добавит TASK22 (white-label) или TASK37 (group threading), когда
/// participant-rendering станет частью UI-пути.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isOwn,
    required this.onRetry,
    this.thumbnailRpc,
    this.fullSizeRpc,
    this.onLongPress,
    this.findReplyTarget,
    this.onReplyChipTap,
    this.participantsByMessengerId,
    this.participantsByMatrixId,
    this.readByPeerCount = 0,
    this.isGroupChat = false,
    this.onTapReadStatus,
    this.reactions = const <ReactionGroup>[],
    this.onToggleReaction,
    this.showSenderAvatar = false,
  });

  final ChatMessage message;
  final bool isOwn;

  /// Зовётся при тапе по retry-button у failed bubble. На sent/pending —
  /// not invoked. ChatScreen перенаправляет в `controller.retry(txnId)`.
  final void Function(ChatMessage failed) onRetry;

  /// **TASK19 Chunk 3**: RPC для рендеринга attachment thumbnail/full
  /// в media-сообщениях. Required когда `message.attachment != null`;
  /// если null — bubble просто пропускает attachment render. Production
  /// flow: ChatScreen берёт из runtime singleton.
  final DownloadAttachmentThumbnailRpc? thumbnailRpc;
  final DownloadAttachmentRpc? fullSizeRpc;

  /// **TASK37 Chunk 2**: long-press → message action sheet (Edit/Delete/
  /// Copy). Tombstone (`isDeleted`) — long-press disabled (no actions
  /// available). Пендинг/failed — long-press disabled (нет stable
  /// matrixEventId-а до RPC return).
  final void Function(ChatMessage)? onLongPress;

  /// **TASK16-A**: lookup для reply chip rendering.
  /// `message.replyToMessageId != null` → bubble зовёт closure для
  /// поиска target в `state.messages`. Cache miss (`null`) → placeholder
  /// chip «Original message unavailable» (per Q1 — БЕЗ fetch+scroll
  /// в MVP). ChatScreen wraps `MessagesController.findByEventId`.
  final ChatMessage? Function(String matrixEventId)? findReplyTarget;

  /// **TASK16-A**: tap по reply chip → best-effort scroll-to-original.
  /// Если null — chip non-tappable (display only). ChatScreen передаёт
  /// closure, который пробует найти original в текущем listview-е и
  /// scroll-ится к его позиции; если не виден — silent no-op (MVP).
  final void Function(String matrixEventId)? onReplyChipTap;

  /// **TASK16-A**: participants комнаты, indexed by `messengerUserId` —
  /// нужен для:
  ///   * resolve sender displayName при rendering reply chip header;
  ///   * mention highlighting (filter `@<token>` matches).
  /// `null` → bubble fallback на raw matrix ids / no-mention-styling
  /// (тестовый/MVP path без RoomDetails).
  final Map<int, RoomParticipant>? participantsByMessengerId;

  /// **TASK16-A**: alternative index by `matrixUserId` для resolve-а
  /// reply target sender display name (target.senderMatrixUserId →
  /// participant). Передаётся вместе с messengerId map (оба строятся
  /// в ChatScreen один раз).
  final Map<String, RoomParticipant>? participantsByMatrixId;

  /// **B11 read receipts**: сколько peer-ов прочитали это сообщение.
  /// 0 (default) → одна галочка «sent». 1+ → две синие галочки «read».
  /// Только для own messages — peer-bubbles не показывают индикатор.
  final int readByPeerCount;

  /// **B11 read receipts (groups)**: если `true`, в `_StatusIcon` для
  /// own sent-bubble показывается `Icons.visibility` + counter вместо
  /// `done_all`. Для direct-чатов (`false`) поведение прежнее:
  /// серая ✓ → синяя ✓✓ при прочтении peer-ом.
  final bool isGroupChat;

  /// **B11 read receipts (groups)**: tap по counter-у — открывает
  /// bottom-sheet со списком «Прочитали / Не прочитали». Если `null`
  /// или `isGroupChat=false` — counter non-tappable (status icon
  /// остаётся декоративным).
  final VoidCallback? onTapReadStatus;

  /// **Emoji reactions**: агрегированные группы реакций (emoji × count)
  /// под bubble. Пустой list → чипы не рендерятся. Свои реакции
  /// (`group.mine`) подсвечены accent-цветом.
  final List<ReactionGroup> reactions;

  /// **Emoji reactions**: tap по чипу → toggle своей реакции с этим
  /// emoji-ключом. Если `null` — чипы display-only (не tappable).
  final void Function(String key)? onToggleReaction;

  /// **B16-ext (phase 2)**: показать аватар отправителя слева от bubble.
  /// Только для peer-сообщений в group-чатах (`!isOwn && isGroupChat`).
  /// ChatScreen ставит `true` на нижнем сообщении серии одного отправителя
  /// (Telegram-style); на остальных group-peer bubble-ах рендерится
  /// spacer той же ширины — для выравнивания. Для own/direct — игнор.
  final bool showSenderAvatar;

  /// Ширина левого gutter-а под аватар (avatar + gap). Держим в одном
  /// месте, чтобы avatar и spacer совпадали.
  static const double _kAvatarSize = 28;
  static const double _kAvatarGap = 8;

  /// Левый gutter peer-bubble в group-чате: аватар отправителя на нижнем
  /// сообщении серии (`showSenderAvatar`), иначе spacer той же ширины.
  Widget _buildLeadingAvatar() {
    if (!showSenderAvatar) {
      return const SizedBox(width: _kAvatarSize + _kAvatarGap);
    }
    final p = participantsByMatrixId?[message.senderMatrixUserId];
    final name =
        p?.displayName ??
        _matrixLocalpart(message.senderMatrixUserId) ??
        message.senderMatrixUserId;
    return Padding(
      padding: const EdgeInsets.only(right: _kAvatarGap),
      child: NsgAvatarImage(
        mxcUrl: p?.avatarUrl,
        fallbackName: name,
        size: _kAvatarSize,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    // TASK22 Chunk 2: domain tokens — host-app может override через
    // `NsgMessengerTheme.bubbleTokens`. Fallback на константы из
    // TASK15 Chunk 2 (никаких visual breaking changes для existing
    // tests / customer integrations без override).
    final tokens =
        theme.extension<NsgMessageBubbleTokens>() ??
        NsgMessageBubbleTokens.fallback;

    final bubbleColor = isOwn
        ? colors.primaryContainer
        : colors.surfaceContainerHighest;
    final textColor = isOwn ? colors.onPrimaryContainer : colors.onSurface;

    final align = isOwn ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final mainAlign = isOwn ? MainAxisAlignment.end : MainAxisAlignment.start;

    final lang = Localizations.maybeLocaleOf(context)?.languageCode ?? 'en';
    // RelativeTimeText сам пересчитывает строку каждую минуту — без него
    // bubble замораживал бы «только что» до следующего setState от
    // родителя (см. doc у `RelativeTimeText`).
    final l = NsgL10n.of(context);
    // TASK37: tombstone — italic «Message deleted» placeholder. Body
    // cleared, attachment hidden, long-press disabled. Telegram-style.
    final isTombstone = message.isDeleted;
    final tombstoneColor = textColor.withValues(alpha: 0.55);
    // TASK37: long-press enabled только когда есть stable matrixEventId
    // (sent) И callback задан И не tombstone. Pending/failed — нет
    // stable id; tombstone — нет actions (Edit/Delete already-deleted).
    final canLongPress =
        onLongPress != null &&
        message.isSent &&
        !isTombstone &&
        message.matrixEventId != null;

    return Padding(
      // TASK22 Phase2 Chunk 1: vertical = interBubbleSpacing / 2 — соседние
      // bubble-ы дают суммарный gap == full interBubbleSpacing. Horizontal
      // остаётся hardcoded — TODO(task22-phase3): tokenize bubble-row margin.
      padding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: tokens.interBubbleSpacing / 2,
      ),
      child: Row(
        mainAxisAlignment: mainAlign,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // B16-ext (phase 2): аватар отправителя слева — только peer-bubble
          // в group-чате. На не-последних сообщениях серии — spacer (выравнивание).
          if (!isOwn && isGroupChat) _buildLeadingAvatar(),
          Flexible(
            child: Column(
              crossAxisAlignment: align,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onLongPress: canLongPress
                      ? () => onLongPress!(message)
                      : null,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth:
                          MediaQuery.of(context).size.width *
                          tokens.maxWidthFraction,
                    ),
                    padding: tokens.padding,
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: isOwn
                          ? tokens.radiusOwn
                          : tokens.radiusPeer,
                    ),
                    child: Column(
                      crossAxisAlignment: align,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isTombstone)
                          Text(
                            l.messageDeletedPlaceholder,
                            style: TextStyle(
                              color: tombstoneColor,
                              fontStyle: FontStyle.italic,
                            ),
                          )
                        else ...[
                          // TASK16-A: reply chip ПЕРЕД attachment/body.
                          if (message.replyToMessageId != null)
                            _ReplyChip(
                              replyToMessageId: message.replyToMessageId!,
                              findReplyTarget: findReplyTarget,
                              onTap: onReplyChipTap,
                              participantsByMatrixId: participantsByMatrixId,
                              textColor: textColor,
                              accentColor: theme.colorScheme.primary,
                            ),
                          // TASK19 Chunk 3: render attachment ПЕРЕД body — UI
                          // convention (image/file сверху, text comment снизу).
                          // Если RPC не передан (text-only screen / test без
                          // mock) — пропускаем attachment, body остаётся.
                          if (message.attachment != null &&
                              thumbnailRpc != null &&
                              fullSizeRpc != null)
                            AttachmentBubble(
                              attachment: message.attachment!,
                              thumbnailRpc: thumbnailRpc!,
                              fullSizeRpc: fullSizeRpc!,
                              textColor: textColor,
                            ),
                          // Body fallback — для media-сообщения это часто
                          // filename / generic «image» (см. server-side
                          // `defaultAttachmentBody`). Hide-аем если body
                          // совпадает с filename — UI уже показал filename
                          // в `_FileRow`. Для image — body почти всегда
                          // filename, рендерим только если non-empty и не
                          // равно filename.
                          if (_shouldRenderBodyText(message))
                            _BodyText(
                              body: message.body,
                              mentionedMessengerUserIds:
                                  message.mentionedMessengerUserIds,
                              participantsByMessengerId:
                                  participantsByMessengerId,
                              textColor: textColor,
                              mentionColor: theme.colorScheme.primary,
                            ),
                        ],
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RelativeTimeText(
                              timestamp: message.serverTimestamp.toLocal(),
                              lang: lang,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: textColor.withValues(alpha: 0.7),
                                fontSize: 11,
                              ),
                            ),
                            // TASK37: «edited» badge. Не показываем для
                            // tombstone (deleted overrides everything).
                            if (message.isEdited && !isTombstone) ...[
                              const SizedBox(width: 4),
                              Text(
                                '· ${l.messageEditedBadge}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: textColor.withValues(alpha: 0.6),
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                            if (isOwn && !isTombstone) ...[
                              const SizedBox(width: 6),
                              _StatusIcon(
                                status: message.status,
                                color: textColor,
                                size: tokens.statusIconSize,
                                onRetry: () => onRetry(message),
                                retryTooltip: l.commonRetry,
                                readByPeerCount: readByPeerCount,
                                isGroupChat: isGroupChat,
                                onTapReadStatus: onTapReadStatus,
                                accentColor: theme.colorScheme.primary,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // **Emoji reactions**: чипы под bubble (emoji × count).
                // Hidden когда нет реакций или это tombstone.
                if (!isTombstone && reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _ReactionChips(
                      reactions: reactions,
                      onToggle: onToggleReaction,
                      align: align,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// **Emoji reactions**: горизонтальный Wrap чипов «emoji × count» под
/// bubble. Свои реакции (`group.mine`) подсвечены accent-цветом + рамкой.
/// Tap → toggle через [onToggle].
class _ReactionChips extends StatelessWidget {
  const _ReactionChips({
    required this.reactions,
    required this.onToggle,
    required this.align,
  });

  final List<ReactionGroup> reactions;
  final void Function(String key)? onToggle;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      alignment: align == CrossAxisAlignment.end
          ? WrapAlignment.end
          : WrapAlignment.start,
      children: [
        for (final r in reactions)
          _ReactionChip(
            group: r,
            mineColor: colors.primaryContainer,
            mineBorder: colors.primary,
            plainColor: colors.surfaceContainerHighest,
            textColor: colors.onSurface,
            onTap: onToggle == null ? null : () => onToggle!(r.key),
          ),
      ],
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({
    required this.group,
    required this.mineColor,
    required this.mineBorder,
    required this.plainColor,
    required this.textColor,
    required this.onTap,
  });

  final ReactionGroup group;
  final Color mineColor;
  final Color mineBorder;
  final Color plainColor;
  final Color textColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: group.mine ? mineColor : plainColor,
        borderRadius: BorderRadius.circular(12),
        border: group.mine ? Border.all(color: mineBorder, width: 1) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(group.key, style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            '${group.count}',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.85),
              fontSize: 12,
              fontWeight: group.mine ? FontWeight.w700 : FontWeight.w500,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return chip;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: chip,
    );
  }
}

/// Не рендерим body text для attachment-message если body совпадает с
/// filename (default Matrix convention — body для clients без attachment
/// rendering = filename). UI уже показал filename внутри FileRow или
/// игнорирует для image preview, дублирование добавляет noise.
bool _shouldRenderBodyText(ChatMessage m) {
  if (m.body.isEmpty) return false;
  final attachment = m.attachment;
  if (attachment == null) return true; // plain text — render всегда.
  // Defaults: для image/video — body == filename → hide.
  // Для file — body == filename → также hide (FileRow показал).
  if (m.body == attachment.originalFilename) return false;
  // User добавил отдельный comment к media (Matrix supports — caller
  // подставил `body` отличный от filename) — rendering нужен.
  return true;
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({
    required this.status,
    required this.color,
    required this.size,
    required this.onRetry,
    required this.retryTooltip,
    this.readByPeerCount = 0,
    this.isGroupChat = false,
    this.onTapReadStatus,
    this.accentColor,
  });

  final ChatMessageStatus status;
  final Color color;
  final double size;
  final VoidCallback onRetry;
  final String retryTooltip;

  /// **B11 read receipts**: 0 → одна серая галочка (sent); 1+ → две
  /// синие (read). Только для status=sent; pending/failed игнорируют.
  final int readByPeerCount;

  /// **B11 group receipts**: если `true`, sent-status рендерится как
  /// глаз + цифра (вместо ✓/✓✓). Цвет глаза синий если count > 0,
  /// серый иначе. Tap по группе глаз+число → [onTapReadStatus].
  final bool isGroupChat;
  final VoidCallback? onTapReadStatus;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    // Exhaustive switch по enum — если в будущем добавится status, dart
    // analyzer заставит обновить ветку (см. ревью 7038189 #3 про
    // sealed-enum compile guarantees).
    switch (status) {
      case ChatMessageStatus.pending:
        return SizedBox(
          width: size - 2,
          height: size - 2,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: color.withValues(alpha: 0.7),
          ),
        );
      case ChatMessageStatus.sent:
        // **B11 group**: для group-чатов — глаз + count. Tap → bottom-
        // sheet «прочитали / не прочитали». Counter всегда виден
        // (даже 0), чтобы юзер мог открыть детальный список и убедиться
        // что никто ещё не открыл.
        if (isGroupChat) {
          final hasReaders = readByPeerCount > 0;
          final iconColor = hasReaders
              ? (accentColor ?? Colors.lightBlueAccent.shade400)
              : color.withValues(alpha: 0.7);
          final indicator = Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$readByPeerCount',
                  style: TextStyle(
                    color: iconColor,
                    fontSize: size - 4,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(Icons.visibility, size: size, color: iconColor),
              ],
            ),
          );
          if (onTapReadStatus == null) return indicator;
          return InkWell(
            onTap: onTapReadStatus,
            borderRadius: BorderRadius.circular(6),
            child: indicator,
          );
        }
        // **B11 direct**: read → две синие галочки (Telegram-style).
        if (readByPeerCount > 0) {
          return Icon(
            Icons.done_all,
            size: size,
            color: Colors.lightBlueAccent.shade400,
          );
        }
        return Icon(
          Icons.check,
          size: size,
          color: color.withValues(alpha: 0.7),
        );
      case ChatMessageStatus.failed:
        return Tooltip(
          message: retryTooltip,
          child: InkWell(
            onTap: onRetry,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(
                Icons.error_outline,
                size: size + 2,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        );
    }
  }
}

/// **TASK16-A**: chip над body bubble, показывающий original message
/// для reply. Lookup через `findReplyTarget(replyToMessageId)`:
///   * found → header `<senderDisplayName>`, preview body (1 line, эллипсис).
///   * miss → italic placeholder «Original message unavailable» (per Q1
///     — без fetch+scroll-to-original в MVP; Phase2 backlog).
class _ReplyChip extends StatelessWidget {
  const _ReplyChip({
    required this.replyToMessageId,
    required this.findReplyTarget,
    required this.onTap,
    required this.participantsByMatrixId,
    required this.textColor,
    required this.accentColor,
  });

  final String replyToMessageId;
  final ChatMessage? Function(String)? findReplyTarget;
  final void Function(String)? onTap;
  final Map<String, RoomParticipant>? participantsByMatrixId;
  final Color textColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final target = findReplyTarget?.call(replyToMessageId);

    final String header;
    final String preview;
    if (target == null) {
      header = '';
      preview = l.replyChipUnavailable;
    } else {
      final p = participantsByMatrixId?[target.senderMatrixUserId];
      header = p?.displayName ?? target.senderMatrixUserId;
      // Tombstone target → preview = «Message deleted» italic-style;
      // attachment-only без body — fallback на filename/generic.
      if (target.isDeleted) {
        preview = l.messageDeletedPlaceholder;
      } else if (target.body.isNotEmpty) {
        preview = target.body;
      } else if (target.attachment != null) {
        preview = target.attachment!.originalFilename;
      } else {
        preview = '';
      }
    }

    final tappable = target != null && onTap != null;
    final chip = Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: accentColor, width: 3)),
        color: textColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header.isNotEmpty)
            Text(
              header,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: accentColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          Text(
            preview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor.withValues(alpha: 0.75),
              fontSize: 12,
              fontStyle: target == null ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );

    if (!tappable) return chip;
    return InkWell(
      onTap: () => onTap!(replyToMessageId),
      borderRadius: BorderRadius.circular(4),
      child: chip,
    );
  }
}

/// **TASK16-A**: render body с подсветкой mentions.
///
/// Algorithm:
///   * Если `mentionedMessengerUserIds` empty/null — plain Text.
///   * Build `displayName → resolved` set из mentioned participants.
///   * Scan body regex `@[A-Za-z0-9_.\-]+` → каждый token, если matches
///     одно из mentioned displayNames (case-insensitive) — wrap в
///     accent-coloured TextSpan; иначе — plain. Anti false-positive:
///     literal `@foo` в тексте без mention intent остаётся не-styled.
///
/// **Self-mention**: на MVP rendering uniform для всех mentioned
/// (Q sign-off — own self-mention identical visually). Push-route
/// usage отдельно (TASK20 push routing).
/// Максимальное число строк для свёрнутого bubble.
///
/// При превышении показывается ссылка «Показать полностью» (см.
/// `l.messageShowMore`); по tap-у — `_expanded = true`, bubble
/// разворачивается inline. Telegram Web / Slack convention.
///
/// 12 строк — баланс: длинное сообщение не растягивает список на весь
/// экран (вытесняя соседние bubble-ы и ломая scroll-position), но и
/// не превращается в нечитаемый огрызок.
const int _kBodyMaxLinesCollapsed = 12;

/// Пороговая длина body, ниже которой пропускаем `TextPainter`-probe
/// и сразу рендерим без collapse. Дёшево по CPU + 99% сообщений
/// короче.
const int _kBodyProbeMinChars = 250;

class _BodyText extends StatefulWidget {
  const _BodyText({
    required this.body,
    required this.mentionedMessengerUserIds,
    required this.participantsByMessengerId,
    required this.textColor,
    required this.mentionColor,
  });

  final String body;
  final List<int>? mentionedMessengerUserIds;
  final Map<int, RoomParticipant>? participantsByMessengerId;
  final Color textColor;
  final Color mentionColor;

  @override
  State<_BodyText> createState() => _BodyTextState();
}

class _BodyTextState extends State<_BodyText> {
  bool _expanded = false;

  // Unicode property classes для cyrillic / других non-ASCII displaynames
  // (типичный RU customer base: @александр, @дмитрий). ASCII-only regex
  // silently дроп-нул бы highlighting, server-side mention уже resolved.
  static final RegExp _mentionToken = RegExp(
    r'@[\p{L}\p{N}_.\-]+',
    unicode: true,
  );

  @override
  void didUpdateWidget(covariant _BodyText oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Сообщение отредактировали → не сохраняем `_expanded=true` от
    // предыдущего body (новое может быть короче или вообще другое).
    if (oldWidget.body != widget.body) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final span = _buildSpan(context);
    // Короткие сообщения — render без layout-probe (дёшево по CPU).
    if (widget.body.length < _kBodyProbeMinChars) {
      return Text.rich(span);
    }
    if (_expanded) {
      return Text.rich(span);
    }
    final l = NsgL10n.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final tp = TextPainter(
          text: span,
          textDirection: TextDirection.ltr,
          maxLines: _kBodyMaxLinesCollapsed,
        )..layout(maxWidth: constraints.maxWidth);
        if (!tp.didExceedMaxLines) {
          return Text.rich(span);
        }
        // Overflow: render обрезанный + tappable «Показать полностью».
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              span,
              maxLines: _kBodyMaxLinesCollapsed,
              overflow: TextOverflow.fade,
            ),
            const SizedBox(height: 4),
            InkWell(
              onTap: () => setState(() => _expanded = true),
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  l.messageShowMore,
                  style: TextStyle(
                    color: widget.mentionColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Собрать `TextSpan` с подсветкой mentions. Выделено отдельным
  /// методом потому что зовётся и из `Text.rich`, и из `TextPainter`
  /// при probe-е.
  ///
  /// **B19 markdown integration**: сначала прогоняем body через
  /// `parseMarkdownToSpans` (inline bold/italic/code/strike/link),
  /// затем рекурсивно проходим по результирующим leaf-spans и
  /// подсвечиваем mentions. Code-spans (моноширинные) НЕ парсятся
  /// на mentions — это даёт ожидаемое поведение «внутри `code`
  /// ничего не магическое».
  TextSpan _buildSpan(BuildContext context) {
    final base = TextStyle(color: widget.textColor);
    final mdSpans = parseMarkdownToSpans(
      widget.body,
      baseStyle: base,
      accentColor: widget.mentionColor,
    );

    final ids = widget.mentionedMessengerUserIds;
    final byId = widget.participantsByMessengerId;
    if (ids == null || ids.isEmpty || byId == null) {
      return TextSpan(children: mdSpans);
    }

    // Build resolved displayNames lowercase set.
    final allowed = <String>{};
    for (final id in ids) {
      final p = byId[id];
      if (p == null) continue;
      final dn = p.displayName;
      if (dn != null && dn.isNotEmpty) {
        allowed.add(dn.toLowerCase());
      }
      final localpart = _matrixLocalpart(p.matrixUserId);
      if (localpart != null) allowed.add(localpart.toLowerCase());
    }
    if (allowed.isEmpty) return TextSpan(children: mdSpans);

    final mentionStyle = base.copyWith(
      color: widget.mentionColor,
      fontWeight: FontWeight.w600,
    );
    return TextSpan(
      children: _applyMentionsRecursive(
        mdSpans,
        allowed: allowed,
        mentionStyle: mentionStyle,
      ),
    );
  }

  /// Walk-tree: для каждого leaf TextSpan с `.text` — split по
  /// `_mentionToken`, заменяем allowed-mentions на highlighted spans.
  /// Composite spans (с `children`) — рекурсия. Code/link/etc spans с
  /// fontFamily=monospace или TapGestureRecognizer мы НЕ трогаем
  /// (`code` — конвенция «raw text»; link — уже tappable, дополнительный
  /// highlight конфликтует).
  List<InlineSpan> _applyMentionsRecursive(
    List<InlineSpan> spans, {
    required Set<String> allowed,
    required TextStyle mentionStyle,
  }) {
    final result = <InlineSpan>[];
    for (final span in spans) {
      if (span is! TextSpan) {
        result.add(span);
        continue;
      }
      // Composite: рекурсия на children.
      if (span.children != null && span.children!.isNotEmpty) {
        result.add(
          TextSpan(
            style: span.style,
            children: _applyMentionsRecursive(
              span.children!,
              allowed: allowed,
              mentionStyle: mentionStyle,
            ),
          ),
        );
        continue;
      }
      // Skip code-spans (fontFamily = monospace).
      if (span.style?.fontFamily == 'monospace') {
        result.add(span);
        continue;
      }
      // Skip link-spans (имеют recognizer).
      if (span.recognizer != null) {
        result.add(span);
        continue;
      }
      final text = span.text;
      if (text == null || text.isEmpty) {
        result.add(span);
        continue;
      }
      result.addAll(
        _splitMentionsInText(text, span.style, allowed, mentionStyle),
      );
    }
    return result;
  }

  /// Split `text` по `_mentionToken`, эмитим plain/highlighted spans.
  List<InlineSpan> _splitMentionsInText(
    String text,
    TextStyle? baseStyle,
    Set<String> allowed,
    TextStyle mentionStyle,
  ) {
    final out = <InlineSpan>[];
    var cursor = 0;
    for (final match in _mentionToken.allMatches(text)) {
      if (match.start > cursor) {
        out.add(
          TextSpan(text: text.substring(cursor, match.start), style: baseStyle),
        );
      }
      final token = text.substring(match.start, match.end);
      final query = token.substring(1).toLowerCase();
      if (allowed.contains(query)) {
        out.add(TextSpan(text: token, style: mentionStyle));
      } else {
        out.add(TextSpan(text: token, style: baseStyle));
      }
      cursor = match.end;
    }
    if (cursor < text.length) {
      out.add(TextSpan(text: text.substring(cursor), style: baseStyle));
    }
    return out;
  }
}

/// `@user:server` → `user`. Возвращает `null` если строка не
/// matrix-id-shaped (no leading `@` или нет `:`).
String? _matrixLocalpart(String matrixUserId) {
  if (!matrixUserId.startsWith('@')) return null;
  final colonIdx = matrixUserId.indexOf(':');
  if (colonIdx <= 1) return null;
  return matrixUserId.substring(1, colonIdx);
}
