# nsg-connect-sdk

Read-only SDK-бандл NSG Connect для встраивания мессенджера Chatista в Flutter-
приложения. Используется как **git submodule** в host-репозиториях (в т. ч. в
репозитории практики).

## Пакеты

| Пакет | Назначение |
|-------|------------|
| `nsg_messenger` | Основной Flutter SDK (экраны чата, виджеты, тема, i18n) |
| `nsg_messenger_push` | Провайдер push поверх Firebase (опционально) |
| `nsg_connect_client` | Сгенерированный Serverpod-клиент (форма API) |
| `nsg_connect_flutter` | Flutter-glue к Serverpod-клиенту |

## Использование как submodule

```bash
# в host-репозитории:
git submodule add <URL этого репо> sdk
```

Затем host-приложение в своём `pubspec.yaml`:

```yaml
dependencies:
  nsg_messenger:
    path: ../../sdk/nsg_messenger
```

## Важное

- Репозиторий **read-only для потребителей** (студентов). Изменения в SDK — через
  основной монорепозиторий NSG Connect, откуда этот бандл синхронизируется.
- Backend (Serverpod-сервер), админка, инфраструктура и секреты в этот бандл
  **не входят** — только клиентская часть, необходимая для сборки приложений.
