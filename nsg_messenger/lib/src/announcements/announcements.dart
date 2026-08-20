import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../session/auth_retry.dart';

/// **TASK91 (issue #65)**: объявления, которые показываются ПРИ ВХОДЕ в
/// приложение — предупреждение о работах, новость, просьба открыть экран.
///
/// Заявка оператора: «предупреждать о предстоящих работах, нововведениях и
/// прочем… показать текст (один раз потом просмотрено, срок актуальности
/// после которого не показываем), какую форму открыть (путь) и payload».
///
/// **Решать, что показывать, — дело сервера.** Здесь нет ни проверки срока,
/// ни «уже видел»: вторая копия этих правил неизбежно разъедется с первой, и
/// человек увидит предупреждение о работах, которые уже прошли. Клиент
/// показывает то, что ему прислали, и сообщает, что показал.
abstract class AnnouncementsRpc {
  Future<List<AnnouncementView>> pending(String? productExternalKey);
  Future<void> markSeen(int announcementId);
}

class ClientAnnouncementsRpc implements AnnouncementsRpc {
  ClientAnnouncementsRpc(this._client);

  final Client _client;

  @override
  Future<List<AnnouncementView>> pending(String? productExternalKey) =>
      withAuthRetry(
        () => _client.messenger.listAnnouncements(
          productExternalKey: productExternalKey,
        ),
        MessengerRuntime.instance.sessionManager,
      );

  @override
  Future<void> markSeen(int announcementId) => withAuthRetry(
    () => _client.messenger.markAnnouncementSeen(
      announcementId: announcementId,
    ),
    MessengerRuntime.instance.sessionManager,
  );
}

/// Показать накопившиеся объявления по одному, отмечая каждое просмотренным.
///
/// [onOpenRoute] — куда вести по кнопке действия у объявления вида `route`.
/// Маршрут в терминах ПРОДУКТА, и разбирать его умеет только хост-приложение;
/// SDK не знает ни его экранов, ни его навигации. Не передан — кнопки не
/// будет, но текст человек всё равно прочтёт.
///
/// **Ошибки глотаются.** Это фоновая любезность на старте: не показать
/// объявление неприятно, уронить вход в приложение — несравнимо хуже.
Future<void> showPendingAnnouncements(
  BuildContext context, {
  String? productExternalKey,
  void Function(String route, String? payloadJson)? onOpenRoute,
  AnnouncementsRpc? rpcOverride,
}) async {
  final rpc =
      rpcOverride ?? ClientAnnouncementsRpc(MessengerRuntime.instance.client);
  List<AnnouncementView> items;
  try {
    items = await rpc.pending(productExternalKey);
  } catch (_) {
    return;
  }
  for (final a in items) {
    if (!context.mounted) return;
    final opened = await _showOne(context, a, onOpenRoute != null);
    // **Отмечаем ПОСЛЕ показа, а не до.** Пометить заранее — значит потерять
    // объявление у того, кто закрыл приложение, не дочитав: сервер уже
    // считает его прочитанным, а человек его не видел.
    try {
      await rpc.markSeen(a.id);
    } catch (_) {
      // Не отметилось — покажем в следующий раз. Повтор безобиднее пропажи.
    }
    if (opened && onOpenRoute != null && a.route != null) {
      onOpenRoute(a.route!, a.payloadJson);
      // Уводим человека по маршруту — остальные объявления показывать поверх
      // чужого экрана нельзя, покажем при следующем входе.
      return;
    }
  }
}

Future<bool> _showOne(
  BuildContext context,
  AnnouncementView a,
  bool canOpenRoute,
) async {
  final l = NsgL10n.of(context);
  final theme = Theme.of(context);
  final warning = a.severity == 'warning';
  final showAction = a.kind == 'route' && a.route != null && canOpenRoute;
  final result = await showDialog<bool>(
    context: context,
    // Объявление о работах человек должен закрыть осознанно, а не смахнуть
    // случайным тапом мимо — иначе он его больше не увидит.
    barrierDismissible: false,
    builder: (dctx) => AlertDialog(
      key: const Key('announcementDialog'),
      icon: Icon(
        warning ? Icons.warning_amber_rounded : Icons.campaign_outlined,
        color: warning ? theme.colorScheme.error : theme.colorScheme.primary,
      ),
      title: Text(a.title),
      content: SingleChildScrollView(child: Text(a.body)),
      actions: [
        TextButton(
          key: const Key('announcementDismiss'),
          onPressed: () => Navigator.of(dctx).pop(false),
          child: Text(l.announcementDismiss),
        ),
        if (showAction)
          FilledButton(
            key: const Key('announcementOpen'),
            onPressed: () => Navigator.of(dctx).pop(true),
            child: Text(l.announcementOpen),
          ),
      ],
    ),
  );
  return result ?? false;
}
