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
