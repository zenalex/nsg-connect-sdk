## 12.08.2026 — доставка, диагностика и то, что молчало

Записано в день работ. Общая нить: сломанное у нас молчало, а исправное
шумело — и то и другое одинаково мешало верить своим же признакам.

* **Квитанции прочтения в тредах чинены** (issue #112). Квитанция на корень
  треда уходила с `thread_id`, равным ей самой; Matrix такое отвергает, а
  отказ останавливал ВЕСЬ markRead — счётчик комнаты не обнулялся никогда.
  Чат поддержки набрал 40 непрочитанных при ежедневном чтении.
* **Оффлайн-лента больше не рисуется вверх ногами** (issue #112). Дисковый
  кэш отдавал сообщения по возрастанию, а лента (`reverse: true`) кладёт
  индекс 0 на дно экрана — до прихода сети внизу стояло самое старое
  сохранённое сообщение.
* **`NsgMessengerDiagnostics`** (issue #117) — точка подключения трекера
  ошибок для хоста. SDK от Sentry не зависит; сюда уходят УСТОЙЧИВЫЕ отказы
  фоновых операций (сейчас — markRead), различаемые по повторяемости, а не
  по типу исключения.
* **Порог отчёта о пропаже связи — по длительности** (issue #118). Прежний
  считался в попытках и срабатывал через полторы секунды, то есть на любом
  рестарте сервера.
* **Непрочитанное в тредах задач** (issue #113) — горизонт чтения на тред,
  счётчик в `TicketView`/`RoomTaskView`, бейдж в строках списка задач.
* **Pulse**: экран разрешённых целей проб с массовой вставкой, перенос
  монитора между папками, правка цели пробы, признак здоровья доставки
  уведомлений по продуктам (issue #120).

## Пропуск: июнь — август 2026

**Этот файл не вёлся с 29.05.2026** (последняя запись — B19 ниже), а SDK за
это время вырос примерно на 340 коммитов. Восстанавливать построчно нечего:
источник правды — история git, `git log -- sdk/nsg_messenger`. Ниже — карта
того, что появилось, чтобы по ней было понятно, где искать.

Запись сделана 06.08.2026, когда обнаружилось, что README всё ещё называет
SDK «TASK11 skeleton, экраны — заглушки».

### Крупное

* **Звонки 1:1** (TASK46) — `CallController` + sealed `CallState`,
  `WebRtcAdapter`/`CallRpc`, глобальный `CallOverlayHost`, кнопка «Позвонить»
  в `ChatScreen`, нативный входящий звонок в фоне на Android/iOS.
* **Треды задач** (TASK82) — отдельная лента обсуждения под сообщением,
  двусторонний мост с внешним трекером; реплики треда в общую ленту комнаты
  НЕ попадают, и это разделение определяет поведение превью и уведомлений.
* **Обращения и задачи** (TASK57/83/84/88/90) — `Ticket` со стадией,
  значок задачи на сообщении, экраны «Мои обращения» и «Задачи», список
  задач комнаты.
* **Команды и поддержка** (TASK43/45/73) — `SupportTeam`, экран команды,
  каталог объектовых чатов, поддержка на уровне тенанта.
* **Папки чатов** (TASK44) — авто-папки и системные папки продуктов.
* **Объявления** (TASK91) — показ при входе в приложение.
* **Голосовые сообщения**, реакции, кросс-room поиск, вложения и альбомы
  с просмотром/сохранением, блочный и inline код, markdown-тулбар.
* **Профиль и i18n** (TASK64) — мультиязычный профиль; SDK применяет свою
  локаль независимо от host-app.

### Заметное для host-app

* `MessagesRpc` и `NsgMessengerRooms` расширялись многократно — сверяйтесь
  с интерфейсами, а не с этим файлом.
* `RoomSummary.lastMessageThreadRootEventId` (issue #92) — не null, когда
  превью строки показывает реплику ОБСУЖДЕНИЯ. Тап по такой строке обязан
  открыть тред: сообщения, которое она показывает, в ленте комнаты нет.
* `taskStageLabel` / `taskStageColor` знают шесть стадий: к
  `new`/`in_progress`/`accepted`/`rejected` добавились `awaiting_user` и
  `on_hold` (issue #98). Значение — строка, незнакомое не должно ронять UI.
* Сторож живости стрима (#84): клиент больше не молчит вечно при разрыве.

## Unreleased (after 0.0.1)

### Added
* **B16-ext: avatars.** `NsgMessenger.uploadUserAvatar(bytes, mimeType)`
  + `NsgAvatarImage` widget (mxc thumbnail через server-proxy + gradient-
  initials fallback). Avatar render в chat row / participants /
  read-receipts sheet / group settings / user-tiles.
* **B17: in-room search.** `MessagesController.searchMessages(query) →
  List<ChatMessage>` поверх server-side Matrix `/search` с pagination
  fallback. UI: `_SearchInRoomScreen` (debounce 350ms, highlight,
  день недели в дате), nav-bar над списком (idx/total + prev/next/
  close), persistence query+results.
* **B18: QR-share.** Не в SDK напрямую (chatista только) — payload
  format и сканер живут в `apps/chatista`.
* **B19: inline markdown.** `parseMarkdownToSpans(text, baseStyle,
  accentColor)` — bold / italic / strike / code / link с conservative
  regex (word-boundary guards). Интеграция с mention highlighting в
  `_BodyText`. Зависимость `url_launcher: ^6.3.0` для tap-link.
* **Group management.** `NsgMessengerRooms.listKnownContacts()`. Новые
  SDK экраны: `GroupSettingsScreen` (rename / participants / add /
  dissolve) + `AddMembersToGroupScreen` (multi-select из contacts +
  search, последовательный invite). `ParticipantsScreen` теперь
  показывает явный `more_vert` для admin/owner.
* **`NsgMessenger.session`** геттер — host-app может читать
  `messengerUserId / displayName / avatarUrl / ...` напрямую.

### Fixed
* **Reconnect storm on desktop.** `MessengerEventBus.forceReconnect`
  теперь no-op в healthy state. `MessengerRuntime` вызывает его на
  `resumed` lifecycle только на iOS / Android. Раньше каждый Alt+Tab
  на Windows рвал WebSocket.
* **Filter on ephemeral events.** `MessagesController.init()` фильтр
  на event-stream больше не блокирует `typingChanged` /
  `readReceiptUpdated` (раньше `e.message != null` отсекал их).

### Changed
* `MessagesRpc` контракт расширен: `searchMessages`. Test stubs в
  репозитории SDK обновлены (4 файла).

## 0.0.1

* TODO: Describe initial release.
