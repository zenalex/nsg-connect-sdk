import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/generated/nsg_l10n.dart';
import '../messenger_runtime.dart';
import '../support/object_rooms_catalog_controller.dart';
import '../support/object_rooms_catalog_rpc.dart';
import '../support/object_rooms_catalog_state.dart';
import 'chat_screen.dart';

/// **TASK45 фаза 1 п.5**: экран каталога объектовых комнат продукта для
/// члена команды поддержки NSG.
///
/// Модель «видит-но-не-беспокоит» (§3.10): команда не входит в объектовые
/// комнаты по умолчанию, но видит их каталог и может войти по запросу.
/// Тап по строке:
///   * если ещё не участник → join (войти) + открыть чат;
///   * если уже участник → просто открыть чат.
/// В открытом чате — обычный [ChatScreen]. Кнопка «Выйти из чата» на
/// строке (для вошедших) — leave, когда вопрос решён.
///
/// Доступ гейтится сервером: не-член команды получает
/// [NotSupportTeamMemberException] → экран показывает «недоступно».
/// Открывается через `NsgMessenger.openObjectRoomsCatalog(...)`.
class ObjectRoomsCatalogScreen extends StatefulWidget {
  const ObjectRoomsCatalogScreen({
    super.key,
    required this.productExternalKey,
    this.productDisplayName,
    @visibleForTesting this.rpcOverride,
    @visibleForTesting this.onOpenRoom,
  });

  final String productExternalKey;

  /// Человекочитаемое имя продукта для заголовка. null → используем ключ.
  final String? productDisplayName;

  /// Visible-for-testing — подмена RPC без Serverpod-клиента.
  final ObjectRoomsCatalogRpc? rpcOverride;

  /// Visible-for-testing — подмена навигации в чат (в проде — открытие
  /// [ChatScreen] через Navigator).
  final void Function(BuildContext context, int roomId)? onOpenRoom;

  @override
  State<ObjectRoomsCatalogScreen> createState() =>
      _ObjectRoomsCatalogScreenState();
}

class _ObjectRoomsCatalogScreenState extends State<ObjectRoomsCatalogScreen> {
  late final ObjectRoomsCatalogController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ObjectRoomsCatalogController(
      rpc:
          widget.rpcOverride ??
          ClientObjectRoomsCatalogRpc(MessengerRuntime.instance.client),
      productExternalKey: widget.productExternalKey,
    );
    unawaited(_controller.init());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openRoom(int roomId) async {
    final opener = widget.onOpenRoom;
    if (opener != null) {
      opener(context, roomId);
      return;
    }
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => ChatScreen(roomId: roomId)));
  }

  Future<void> _onTapRoom(NsgL10n l, ProductObjectRoom room) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (room.viewerIsMember) {
      await _openRoom(room.roomId);
      return;
    }
    // Войти и открыть.
    final details = await _controller.join(room.roomId);
    if (!mounted) return;
    if (details == null) {
      messenger?.showSnackBar(
        SnackBar(content: Text(l.objectRoomsCatalogJoinFailed)),
      );
      return;
    }
    await _openRoom(room.roomId);
  }

  Future<void> _onLeave(NsgL10n l, ProductObjectRoom room) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final ok = await _controller.leave(room.roomId);
    if (!mounted) return;
    messenger?.showSnackBar(
      SnackBar(
        content: Text(
          ok ? l.objectRoomsCatalogLeaveDone : l.supportTeamActionFailed,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    final title = l.objectRoomsCatalogTitle(
      widget.productDisplayName ?? widget.productExternalKey,
    );
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final state = _controller.state;
          return switch (state) {
            ObjectRoomsCatalogLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            ObjectRoomsCatalogUnavailable() => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l.objectRoomsCatalogUnavailable,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            ObjectRoomsCatalogReady(:final rooms, :final busyRoomId) =>
              rooms.isEmpty
                  ? Center(child: Text(l.objectRoomsCatalogEmpty))
                  : RefreshIndicator(
                      onRefresh: _controller.refresh,
                      child: ListView.separated(
                        itemCount: rooms.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, i) =>
                            _buildTile(l, rooms[i], busyRoomId),
                      ),
                    ),
          };
        },
      ),
    );
  }

  Widget _buildTile(NsgL10n l, ProductObjectRoom room, int? busyRoomId) {
    final busy = busyRoomId == room.roomId;
    final subtitle = room.lastMessagePreview?.trim();
    return ListTile(
      key: Key('objectRoomTile_${room.roomId}'),
      leading: CircleAvatar(
        child: Icon(
          room.viewerIsMember ? Icons.chat : Icons.apartment_outlined,
        ),
      ),
      title: Text(room.name ?? '#${room.roomId}'),
      subtitle: (subtitle != null && subtitle.isNotEmpty)
          ? Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis)
          : null,
      trailing: busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : room.viewerIsMember
          ? PopupMenuButton<String>(
              key: Key('objectRoomLeaveMenu_${room.roomId}'),
              onSelected: (_) => _onLeave(l, room),
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  value: 'leave',
                  child: Text(l.objectRoomsCatalogLeaveAction),
                ),
              ],
            )
          : Chip(
              label: Text(
                '${room.totalParticipants}',
                style: const TextStyle(fontSize: 12),
              ),
              visualDensity: VisualDensity.compact,
            ),
      onTap: busy ? null : () => _onTapRoom(l, room),
    );
  }
}
