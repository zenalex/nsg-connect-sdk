/// **Здоровье доставки уведомлений по продуктам** (issue #120).
///
/// Отсутствие пушей выглядит как тишина: ни экрана, ни лога. Что у всех
/// продуктов, кроме Chatista, ноль зарегистрированных устройств, выяснилось
/// запросом в прод-базу — при полностью готовой нашей стороне. Этот экран
/// делает такое состояние видимым до того, как о нём скажет пользователь
/// словами «мне ничего не приходит».
///
/// Строка отвечает на два разных вопроса, и они адресованы разным людям:
/// «нет устройств» чинит интегратор в своём приложении, «нет ключей» — мы у
/// себя. Поэтому вердикт назван словами, а не цветом.
library;

import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../admin/nsg_messenger_platform_admin.dart';
import '../i18n/generated/nsg_l10n.dart';
import '../utils/relative_time.dart';

class DeliveryHealthScreen extends StatefulWidget {
  const DeliveryHealthScreen({super.key, required this.admin});

  final NsgMessengerPlatformAdmin admin;

  @override
  State<DeliveryHealthScreen> createState() => _DeliveryHealthScreenState();
}

class _DeliveryHealthScreenState extends State<DeliveryHealthScreen> {
  late Future<List<ProductDeliveryHealth>> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.admin.listDeliveryHealth();
  }

  Future<void> _refresh() async {
    setState(() => _future = widget.admin.listDeliveryHealth());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l.deliveryHealthTitle)),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<ProductDeliveryHealth>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snap.data ?? const <ProductDeliveryHealth>[];
            if (items.isEmpty) {
              // Сбой запроса деградирует в пустой список (см. фасад), и это
              // состояние честнее зелёного: признак ради того и заводится.
              return ListView(
                children: [
                  const SizedBox(height: 96),
                  Center(child: Text(l.deliveryHealthEmpty)),
                ],
              );
            }
            return ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, i) => _HealthTile(item: items[i]),
            );
          },
        ),
      ),
    );
  }
}

class _HealthTile extends StatelessWidget {
  const _HealthTile({required this.item});

  final ProductDeliveryHealth item;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final theme = Theme.of(context);
    final (icon, color, verdict) = switch (item.verdict) {
      'ok' => (Icons.check_circle_outline, Colors.green, l.deliveryHealthOk),
      'noDevices' => (
        Icons.phonelink_erase_outlined,
        Colors.orange,
        l.deliveryHealthNoDevices,
      ),
      'noCredentials' => (
        Icons.key_off_outlined,
        theme.colorScheme.error,
        l.deliveryHealthNoCredentials,
      ),
      'stale' => (
        Icons.hourglass_disabled_outlined,
        Colors.orange,
        l.deliveryHealthStaleAll,
      ),
      // Незнакомый вердикт с более нового сервера показываем как есть, а не
      // прячем: молчать о непонятном — та же тишина, против которой экран.
      _ => (Icons.help_outline, theme.colorScheme.outline, item.verdict),
    };

    final keys = <String>[
      if (item.hasFcmCredentials) 'FCM',
      if (item.hasRustoreCredentials) 'RuStore',
      if (item.hasVoipCredentials) 'VoIP',
    ];

    return ListTile(
      isThreeLine: true,
      leading: Icon(icon, color: color),
      // Транспорт последней мили (issue #121) — в заголовке, а не мелким
      // шрифтом внизу: от него зависит, что вообще значат остальные
      // строки. Ноль устройств у продукта на вебхуке — норма, а не
      // поломка, и читать вердикт, не зная транспорта, нельзя.
      title: Text(
        '${item.productDisplayName} · ${item.productExternalKey}'
        ' · ${item.deliveryTransport}'
        // Значение, которого мы не понимаем, названо прямо: доставка идёт
        // platformPush, и молчать об этом расхождении нельзя.
        '${item.deliveryTransportKnown ? '' : ' (?)'}',
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(verdict, style: TextStyle(color: color)),
          Text(
            l.deliveryHealthDevices(
              item.devicesFcm,
              item.devicesRustore,
              item.devicesVoip,
            ),
            style: theme.textTheme.bodySmall,
          ),
          Text(
            keys.isEmpty
                ? l.deliveryHealthNoKeys
                : l.deliveryHealthKeys(keys.join(', ')),
            style: theme.textTheme.bodySmall,
          ),
          Text(
            item.lastSeenAt == null
                ? l.deliveryHealthNever
                // Дата последнего продления отвечает на вопрос «а токены-то
                // живые»: у пользующегося человека регистрация обновляется
                // на каждом запуске приложения.
                : '${formatRelativeTime(item.lastSeenAt!.toLocal(), lang: Localizations.localeOf(context).languageCode, shortEn: false)}'
                      '${item.staleDevices > 0 ? ' · ${l.deliveryHealthStale(item.staleDevices)}' : ''}',
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
