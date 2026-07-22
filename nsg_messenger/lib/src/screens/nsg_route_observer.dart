import 'package:flutter/widgets.dart';

/// **Issue #55**: наблюдатели навигации, через которые SDK узнаёт, что
/// экран чата перекрыт другим маршрутом ПОВЕРХ (профиль, настройки,
/// галерея) — и снова открыт.
///
/// Зачем это вообще: живой (не dispose-нутый) `ChatScreen` под чужим
/// маршрутом продолжал считать себя видимым — держал серверный presence
/// `currentRoomId` (push-routing глушил уведомления «пользователю в
/// комнате») и молча метил входящие прочитанными. Ни одна из имевшихся
/// осей видимости (TASK66 `active`, issue #37 `_appResumed` /
/// `_newestVisible`) перекрытие маршрутом не ловит — это отдельная ось,
/// и единственный штатный способ её слушать — [RouteObserver],
/// зарегистрированный у навигатора host-приложения.
class NsgRouteObserver extends RouteObserver<ModalRoute<void>> {
  /// Фильтр [PageRoute]: bottom-sheet-ы и диалоги — тоже `ModalRoute`-ы,
  /// но чат под ними виден (полупрозрачный barrier), и юзер продолжает
  /// читать ленту. Считать их «перекрытием» значило бы ронять presence и
  /// откладывать честный markRead на каждом action-sheet-е сообщения /
  /// пикере вложений / эмодзи — то есть на каждом втором действии в чате.
  /// Полноэкранное перекрытие (профиль/настройки/галерея) — всегда
  /// [PageRoute]; только его и пропускаем к подписчикам.
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route is PageRoute) super.didPop(route, previousRoute);
  }
}

/// Главный наблюдатель — host обязан включить его в
/// `MaterialApp.navigatorObservers` (см. `NsgMessenger.routeObserver`).
/// Не подключён — подписки ChatScreen просто никогда не выстрелят:
/// деградация к прежнему поведению (перекрытие не замечаем), без ошибок.
final NsgRouteObserver nsgPrimaryRouteObserver = NsgRouteObserver();

/// Наблюдатели вложенных навигаторов. Один [RouteObserver] нельзя отдать
/// двум живым навигаторам сразу (assert во Flutter), а у Chatista на
/// десктопе внутричатовые переходы идут через СВОЙ Navigator панели
/// рабочей области — таким навигаторам host создаёт отдельные экземпляры
/// через `NsgMessenger.createNestedRouteObserver`.
final List<NsgRouteObserver> _nestedRouteObservers = <NsgRouteObserver>[];

/// Все зарегистрированные наблюдатели (главный + вложенные) — snapshot.
/// ChatScreen подписывает свой маршрут во все сразу: выстрелит только
/// тот, чьему навигатору маршрут принадлежит, остальные молчат. Это
/// дешевле и надёжнее, чем вручную сопоставлять `route.navigator` с
/// наблюдателями (attach к навигатору происходит позже подписки).
List<RouteObserver<ModalRoute<void>>> get nsgAllRouteObservers =>
    <RouteObserver<ModalRoute<void>>>[
      nsgPrimaryRouteObserver,
      ..._nestedRouteObservers,
    ];

/// Создать и зарегистрировать наблюдатель для вложенного навигатора.
NsgRouteObserver createNestedNsgRouteObserver() {
  final observer = NsgRouteObserver();
  _nestedRouteObservers.add(observer);
  return observer;
}

/// Снять вложенный наблюдатель с учёта (host отпускает его, когда
/// владеющий State умирает). Не снимать — не утечка в строгом смысле
/// (наблюдатель без навигатора молчит), но реестр рос бы бесконечно.
void releaseNestedNsgRouteObserver(RouteObserver<ModalRoute<void>> observer) {
  _nestedRouteObservers.remove(observer);
}
