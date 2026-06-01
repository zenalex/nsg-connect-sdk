import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

/// Устойчивый «отпечаток» MessengerAuthContext-а — детерминированная
/// функция от identity-фактов **без** customer accessToken.
///
/// Зачем: `accessToken` ротируется (это и есть смысл refresh), но
/// «личность» юзера остаётся той же — `tenant + product + provider +
/// externalUserId`. По отпечатку SDK решает:
///   * кэш в `AuthTokenStore` принадлежит ТЕКУЩЕМУ юзеру → используем
///     сохранённую сессию;
///   * fingerprint в storage не совпадает с тем, что вернул provider —
///     это переключение юзера (logout/login в host-app), кэш стираем
///     и идём к серверу за новой сессией.
///
/// SHA-256 hex (64 chars). Не PII: восстановить externalUserId из
/// fingerprint-а нельзя без знания tenant/product/provider, и даже
/// зная их — это полный brute-force по пространству externalUserId.
String authContextFingerprint(MessengerAuthContext ctx) {
  // Каноническая форма: pipe-separator + порядок полей зафиксирован.
  // Менять формат — breaking change для cache (старые записи перестанут
  // совпадать → SDK на старте сделает лишний getAuthContext + session).
  final canonical =
      '${ctx.tenantExternalKey}|'
      '${ctx.productExternalKey ?? ""}|'
      '${ctx.identityProvider.name}|'
      '${ctx.externalUserId}';
  final digest = sha256.convert(utf8.encode(canonical));
  return digest.toString();
}
