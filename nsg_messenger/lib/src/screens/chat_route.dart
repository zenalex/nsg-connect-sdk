import 'package:flutter/material.dart';

import 'chat_screen.dart';
import 'thread_screen.dart';

/// Имя маршрута открытого чата.
///
/// Маршрут НЕ зарегистрирован ни в какой таблице (в приложении вся навигация
/// императивная) — имя нужно ровно для одного: узнать по стеку, открыт ли уже
/// чат этой комнаты. Функция чистая и тестируется без виджетов; главное её
/// свойство — единственное место, где живёт формат имени. Пока формат был
/// продублирован в двух местах (тап по пушу и переход по инвайту), любой
/// третий вход рисковал разъехаться и сломать дедуп.
String chatRouteName(int roomId) => 'chat/$roomId';

/// Лежит ли чат комнаты [roomId] СВЕРХУ стека (виден пользователю прямо
/// сейчас).
///
/// `popUntil` здесь — способ заглянуть в верхний маршрут, а НЕ выталкивание:
/// предикат сразу возвращает `true`, поэтому цикл `popUntil` завершается на
/// первой же итерации и ничего не закрывает. Приём вынужденный — у
/// `NavigatorState` нет публичного доступа к текущему маршруту.
///
/// **Именно верхний, а не «где-то в стеке»**: `popUntil` останавливается на
/// первом маршруте, для которого предикат истинен, так что заглянуть глубже
/// таким способом нельзя. Для дедупа этого достаточно и так задумано —
/// повторный тап по уведомлению из открытого чата не должен ничего делать, а
/// вот открыть чат, который лежит под текущим экраном, — вполне законно.
bool isChatRouteOnTop(NavigatorState navigator, int roomId) {
  final name = chatRouteName(roomId);
  var onTop = false;
  navigator.popUntil((route) {
    onTop = route.settings.name == name;
    return true;
  });
  return onTop;
}

/// Открыть чат [roomId] поверх текущего экрана.
///
/// Единая точка входа для всех «извне» открытых чатов: тап по пуш-уведомлению,
/// переход по инвайт-ссылке и (issue #41) переход к первоисточнику
/// пересланного сообщения. Всегда `push`, никогда не `popUntil(isFirst)` —
/// промежуточные экраны и их состояние сохраняются, чат просто ложится сверху.
///
/// [skipIfOnTop] — поведение по умолчанию для пушей: тап по уведомлению из
/// чата, который прямо сейчас и открыт, не должен класть сверху его копию.
/// Переход к первоисточнику передаёт `false`: там важно не «оказаться в
/// комнате», а доскроллить до конкретного сообщения, поэтому нужен свежий
/// экран с [initialTargetEventId].
Future<void> openChatRoom(
  NavigatorState navigator, {
  required int roomId,
  String? initialTargetEventId,
  bool skipIfOnTop = true,
}) async {
  if (skipIfOnTop && isChatRouteOnTop(navigator, roomId)) return;
  await navigator.push(
    MaterialPageRoute<void>(
      settings: RouteSettings(name: chatRouteName(roomId)),
      builder: (_) => ChatScreen(
        roomId: roomId,
        initialTargetEventId: initialTargetEventId,
      ),
    ),
  );
}

/// Имя маршрута открытого треда. Тредов в комнате много, поэтому в имени и
/// комната, и корень — иначе дедуп считал бы два разных обсуждения одним.
String threadRouteName(int roomId, String threadRootEventId) =>
    'thread/$roomId/$threadRootEventId';

/// Открыть обсуждение задачи (тред) поверх текущего экрана.
///
/// **Инцидент 2026-08-05.** Пуш про ответ в треде уводил в ленту комнаты
/// искать сообщение, которого там быть не может: реплики тредов в общую
/// ленту не попадают (разделение лент, TASK82). Приложение честно
/// прогоняло историю страницами и сдавалось — «Сообщение слишком далеко в
/// истории». Уведомление вело в никуда.
///
/// Дедуп — по [threadRouteName]: повторный тап по тому же уведомлению из
/// уже открытого треда не кладёт сверху его копию (то же правило, что у
/// [openChatRoom]).
Future<void> openThreadRoute(
  NavigatorState navigator, {
  required int roomId,
  required String threadRootEventId,
}) async {
  final name = threadRouteName(roomId, threadRootEventId);
  var onTop = false;
  navigator.popUntil((route) {
    onTop = route.settings.name == name;
    return true;
  });
  if (onTop) return;
  await navigator.push(
    MaterialPageRoute<void>(
      settings: RouteSettings(name: name),
      builder: (_) =>
          ThreadScreen(roomId: roomId, threadRootEventId: threadRootEventId),
    ),
  );
}
