import 'dart:async' show TimeoutException;
import 'dart:io' show SocketException, HandshakeException, HttpException;

import 'package:nsg_connect_client/nsg_connect_client.dart';

/// **B10 / OUTBOX**: классификатор «transient vs permanent» для send-retry.
///
/// **Transient** (ретраим): сетевые/IO ошибки, таймаут, generic
/// `ServerpodClientException` (5xx, parse error в ответе, dropped
/// connection). Эти обычно временные — сервер мог рестартануть, connection
/// упал, retry с тем же `clientTxnId` безопасен (server-side dedup). Офлайн
/// тоже сюда: RPC падает транзиентно → бэкофф → уйдёт при возврате сети.
///
/// **Permanent** (НЕ ретраим): типизированные доменные exception-ы
/// (`MessengerNotAuthenticated`, `RoomNotFound`, …), 401, 403 — ретрай тех
/// же ошибок не поможет; лучше сразу показать failed с retry-кнопкой.
///
/// Общий для [MessagesController] (in-memory send) и [OutboxSender]
/// (персистентная очередь) — единая логика классификации.
bool isTransientSendError(Object error) {
  if (error is TimeoutException) return true;
  if (error is SocketException) return true;
  if (error is HandshakeException) return true;
  if (error is HttpException) return true;
  // Generic Serverpod-client exception (5xx, parse fail, network).
  // Типизированные доменные exception-ы наследуются от
  // SerializableException, а НЕ от ServerpodClientException, поэтому этот
  // match их не зацепит.
  if (error is ServerpodClientException) return true;
  return false;
}
