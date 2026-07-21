import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import 'support_team_rpc.dart';
import 'support_team_state.dart';

/// **TASK43**: контроллер экрана «Команда поддержки». Загружает состав
/// через [SupportTeamRpc.getSupportTeam]; не-участник → состояние
/// [SupportTeamUnavailable]`(unavailable: true)` (host-app скрывает экран).
/// Owner может добавлять/удалять операторов — каждая мутация возвращает
/// свежий view и переустанавливает state.
///
/// Паттерн зеркалит `ChatsListController`: `ChangeNotifier` + sealed
/// state, hand-written fake RPC в тестах.
class SupportTeamController extends ChangeNotifier {
  SupportTeamController({
    required SupportTeamRpc rpc,
    required this.productExternalKey,
  }) : _rpc = rpc;

  final SupportTeamRpc _rpc;
  final String productExternalKey;

  SupportTeamState _state = const SupportTeamLoading();
  SupportTeamState get state => _state;

  bool _disposed = false;
  bool _initialized = false;

  /// Загрузить состав. Double-init — no-op.
  Future<void> init() async {
    if (_initialized || _disposed) return;
    _initialized = true;
    await _load();
  }

  /// Ручной перезапрос (retry после временной ошибки / pull-to-refresh).
  Future<void> refresh() => _load();

  Future<void> _load() async {
    try {
      final view = await _rpc.getSupportTeam(
        productExternalKey: productExternalKey,
      );
      _emit(SupportTeamReady(view: view));
    } catch (e) {
      _emit(
        SupportTeamUnavailable(
          error: e,
          unavailable: e is NotSupportTeamMemberException,
        ),
      );
    }
  }

  /// Добавить оператора по email (owner-only). Возвращает `true` при
  /// успехе. Ошибку прокидывает через `false` + не роняет state (UI
  /// показывает snackbar). Пустой email — no-op `false`.
  Future<bool> addMember(String email, {int tier = 1}) async {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return false;
    final current = _state;
    if (current is! SupportTeamReady) return false;
    _emit(current.copyWith(busy: true));
    try {
      final view = await _rpc.addMember(
        productExternalKey: productExternalKey,
        email: trimmed,
        tier: tier,
      );
      _emit(SupportTeamReady(view: view));
      return true;
    } catch (e) {
      // Возвращаем в не-busy состояние с прежним view.
      _emit(current.copyWith(busy: false));
      return false;
    }
  }

  /// **TASK48**: сменить тир участника (owner-only). `true` при успехе.
  Future<bool> setMemberTier(int targetMessengerUserId, int tier) async {
    final current = _state;
    if (current is! SupportTeamReady) return false;
    _emit(current.copyWith(busy: true));
    try {
      final view = await _rpc.setMemberTier(
        productExternalKey: productExternalKey,
        targetMessengerUserId: targetMessengerUserId,
        tier: tier,
      );
      _emit(SupportTeamReady(view: view));
      return true;
    } catch (e) {
      _emit(current.copyWith(busy: false));
      return false;
    }
  }

  /// **TASK48 iter2**: порог авто-эскалации в минутах (owner-only). `true`
  /// при успехе. Сервер клампит значение в [1, 10080].
  Future<bool> setTimeout(int minutes) async {
    final current = _state;
    if (current is! SupportTeamReady) return false;
    _emit(current.copyWith(busy: true));
    try {
      final view = await _rpc.setTimeout(
        productExternalKey: productExternalKey,
        minutes: minutes,
      );
      _emit(SupportTeamReady(view: view));
      return true;
    } catch (e) {
      _emit(current.copyWith(busy: false));
      return false;
    }
  }

  /// **TASK76**: сменить роль участника `owner` ↔ `member` (owner-only,
  /// назначение других админов). `true` при успехе. Guard последнего
  /// owner-а — на сервере (LastOwnerCannotDemoteException → `false`).
  Future<bool> setMemberRole(
    int targetMessengerUserId,
    SupportTeamRole role,
  ) async {
    final current = _state;
    if (current is! SupportTeamReady) return false;
    _emit(current.copyWith(busy: true));
    try {
      final view = await _rpc.setMemberRole(
        productExternalKey: productExternalKey,
        targetMessengerUserId: targetMessengerUserId,
        role: role,
      );
      _emit(SupportTeamReady(view: view));
      return true;
    } catch (e) {
      _emit(current.copyWith(busy: false));
      return false;
    }
  }

  /// Убрать оператора по messengerUserId (owner-only). `true` при успехе.
  Future<bool> removeMember(int targetMessengerUserId) async {
    final current = _state;
    if (current is! SupportTeamReady) return false;
    _emit(current.copyWith(busy: true));
    try {
      final view = await _rpc.removeMember(
        productExternalKey: productExternalKey,
        targetMessengerUserId: targetMessengerUserId,
      );
      _emit(SupportTeamReady(view: view));
      return true;
    } catch (e) {
      _emit(current.copyWith(busy: false));
      return false;
    }
  }

  void _emit(SupportTeamState s) {
    if (_disposed) return;
    _state = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
