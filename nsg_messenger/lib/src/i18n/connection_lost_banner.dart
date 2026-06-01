import 'package:flutter/material.dart';

import 'generated/nsg_l10n.dart';

/// Шаринговый баннер «соединение потеряно — показываем кэш».
///
/// Используется в [ChatsListScreen] (TASK14) и [ChatScreen] (TASK15)
/// при `state == Error && lastKnown != null`. Раньше дублировался
/// inline в обоих экранах — DRY-fix из ревью TASK15 b0da4a7 #4.
///
/// Сигнатура `(error)` принимает Object для будущего расширения
/// (показать тип ошибки в дев-режиме / разный текст для timeout vs
/// 401 / etc); сейчас отображаем единую строку.
class ConnectionLostBanner extends StatelessWidget {
  const ConnectionLostBanner({super.key, required this.error});

  // ignore: unused_element_parameter
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      color: Theme.of(context).colorScheme.errorContainer,
      child: Text(
        NsgL10n.of(context).commonConnectionLost,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
  }
}
