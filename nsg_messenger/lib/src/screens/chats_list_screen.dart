import 'package:flutter/material.dart';
import 'package:nsg_connect_client/nsg_connect_client.dart';

import '../i18n/connection_lost_banner.dart';
import '../i18n/generated/nsg_l10n.dart';
import '../messenger_mode.dart';
import '../messenger_runtime.dart';
import '../rooms/chats_list_controller.dart';
import '../rooms/chats_list_state.dart';
import '../rooms/room_action_sheet.dart';
import '../rooms/room_summary_tile.dart';
import 'chat_screen.dart';
import 'create_chat_screen.dart';

/// Реальный список чатов (TASK14). Поверх [ChatsListController] —
/// sealed [ChatsListState] с no-flicker `lastKnown` pattern; rebuild
/// через [ListenableBuilder].
class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key, this.mode = MessengerMode.embeddedProduct});

  final MessengerMode mode;

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  late final ChatsListController _controller;
  final TextEditingController _searchCtl = TextEditingController();
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    final runtime = MessengerRuntime.instance;
    _controller = ChatsListController(
      rooms: runtime.rooms,
      events: runtime.eventBus.events,
      sessionStates: runtime.stateStream,
    )..init();
    // Standalone-mode: загружаем product list лениво. В embed-mode
    // dropdown скрыт (мы не зовём loader), но ничего не ломается
    // если повторно вызовешь — `loadAvailableProducts` идемпотентен.
    if (widget.mode == MessengerMode.standalone) {
      _controller.loadAvailableProducts();
    }
  }

  @override
  void dispose() {
    _searchCtl.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openCreate(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const CreateChatScreen()));
    // create-chat pushes ChatScreen напрямую, и cache invalidates через
    // populate-on-create в NsgMessengerRooms. Лишний refresh здесь не
    // нужен (event-bus сам триггернёт когда message-flow начнётся).
  }

  void _enterSearch() {
    setState(() => _searching = true);
  }

  void _exitSearch() {
    _searchCtl.clear();
    _controller.setSearch(null);
    setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _searching
          ? _buildSearchAppBar(context)
          : _buildNormalAppBar(context),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => _Body(
          state: _controller.state,
          searching: _searching,
          onRefresh: () => _controller.refresh(force: true),
          onTapRoom: (id) => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => ChatScreen(roomId: id)),
          ),
          onLongPressRoom: (room) => showRoomActionSheet(
            context: context,
            room: room,
            controller: _controller,
          ),
        ),
      ),
    );
  }

  AppBar _buildNormalAppBar(BuildContext context) {
    final l = NsgL10n.of(context);
    return AppBar(
      title: Text(l.chatsListTitle),
      actions: [
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: l.chatsListSearchTooltip,
          onPressed: _enterSearch,
        ),
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: l.commonNewChat,
          onPressed: () => _openCreate(context),
        ),
        // Product filter — только standalone + >1 product. ListenableBuilder
        // потому что availableProducts грузится async; начально null,
        // потом пополняется.
        if (widget.mode == MessengerMode.standalone)
          ListenableBuilder(
            listenable: _controller,
            builder: (ctx, _) {
              final products = _controller.availableProducts;
              if (products == null || products.length <= 1) {
                return const SizedBox.shrink();
              }
              return _ProductFilterButton(
                controller: _controller,
                products: products,
              );
            },
          ),
        ListenableBuilder(
          listenable: _controller,
          builder: (ctx, _) => _FilterMenuButton(controller: _controller),
        ),
      ],
    );
  }

  AppBar _buildSearchAppBar(BuildContext context) {
    final l = NsgL10n.of(context);
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: _exitSearch,
      ),
      title: TextField(
        controller: _searchCtl,
        autofocus: true,
        decoration: InputDecoration(
          hintText: l.chatsListSearchHint,
          border: InputBorder.none,
        ),
        onChanged: _controller.setSearch,
      ),
      actions: [
        ListenableBuilder(
          listenable: _controller,
          builder: (ctx, _) {
            if (_controller.search == null) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.clear),
              tooltip: l.chatsListSearchClearTooltip,
              onPressed: () {
                _searchCtl.clear();
                _controller.setSearch(null);
              },
            );
          },
        ),
      ],
    );
  }
}

/// AppBar product-filter dropdown (TASK42 Chunk 3, standalone-mode only).
/// Виден когда `availableProducts.length > 1`; иначе UI считает что
/// product filter не имеет смысла (single-product viewer).
class _ProductFilterButton extends StatelessWidget {
  const _ProductFilterButton({
    required this.controller,
    required this.products,
  });

  final ChatsListController controller;
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return PopupMenuButton<int?>(
      tooltip: l.chatsListProductFilterTooltip,
      icon: const Icon(Icons.business_outlined),
      initialValue: controller.productFilter,
      onSelected: controller.setProductFilter,
      itemBuilder: (ctx) => [
        CheckedPopupMenuItem<int?>(
          value: null,
          checked: controller.productFilter == null,
          child: Text(l.chatsListProductFilterAll),
        ),
        ...products.map(
          (p) => CheckedPopupMenuItem<int?>(
            value: p.id,
            checked: controller.productFilter == p.id,
            child: Text(p.displayName),
          ),
        ),
      ],
    );
  }
}

/// AppBar overflow меню с tab-фильтром (TASK42 Chunk 2).
/// Single source of truth — `controller.filter`. На select меняем
/// контроллер; UI ребилд через ListenableBuilder в parent-е.
class _FilterMenuButton extends StatelessWidget {
  const _FilterMenuButton({required this.controller});

  final ChatsListController controller;

  @override
  Widget build(BuildContext context) {
    final l = NsgL10n.of(context);
    return PopupMenuButton<ChatsListFilter>(
      tooltip: l.chatsListFilterMenuTooltip,
      icon: const Icon(Icons.filter_list),
      initialValue: controller.filter,
      onSelected: controller.setFilter,
      itemBuilder: (ctx) => [
        CheckedPopupMenuItem(
          value: ChatsListFilter.active,
          checked: controller.filter == ChatsListFilter.active,
          child: Text(l.chatsListFilterActive),
        ),
        CheckedPopupMenuItem(
          value: ChatsListFilter.archived,
          checked: controller.filter == ChatsListFilter.archived,
          child: Text(l.chatsListFilterArchived),
        ),
        CheckedPopupMenuItem(
          value: ChatsListFilter.all,
          checked: controller.filter == ChatsListFilter.all,
          child: Text(l.chatsListFilterAll),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.searching,
    required this.onRefresh,
    required this.onTapRoom,
    required this.onLongPressRoom,
  });

  final ChatsListState state;
  final bool searching;
  final Future<void> Function() onRefresh;
  final void Function(int roomId) onTapRoom;
  final void Function(RoomSummary room) onLongPressRoom;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ChatsListLoading() => const Center(child: CircularProgressIndicator()),
      ChatsListReady(rooms: final rooms, refreshing: final refreshing) =>
        _Loaded(
          rooms: rooms,
          refreshing: refreshing,
          searching: searching,
          onRefresh: onRefresh,
          onTapRoom: onTapRoom,
          onLongPressRoom: onLongPressRoom,
        ),
      ChatsListError(error: final e, lastKnown: final last) =>
        last == null
            ? _ErrorEmpty(error: e, onRetry: onRefresh)
            : _Loaded(
                rooms: last,
                refreshing: false,
                searching: searching,
                onRefresh: onRefresh,
                onTapRoom: onTapRoom,
                onLongPressRoom: onLongPressRoom,
                errorBanner: e,
              ),
    };
  }
}

class _Loaded extends StatelessWidget {
  const _Loaded({
    required this.rooms,
    required this.refreshing,
    required this.searching,
    required this.onRefresh,
    required this.onTapRoom,
    required this.onLongPressRoom,
    this.errorBanner,
  });

  final List<RoomSummary> rooms;
  final bool refreshing;
  final bool searching;
  final Future<void> Function() onRefresh;
  final void Function(int roomId) onTapRoom;
  final void Function(RoomSummary room) onLongPressRoom;
  final Object? errorBanner;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: Column(
        children: [
          if (errorBanner != null) ConnectionLostBanner(error: errorBanner!),
          if (refreshing) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: rooms.isEmpty
                ? _EmptyState(searching: searching)
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: rooms.length,
                    itemBuilder: (_, i) {
                      final r = rooms[i];
                      return RoomSummaryTile(
                        room: r,
                        onTap: () => onTapRoom(r.id),
                        onLongPress: () => onLongPressRoom(r),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.searching});

  final bool searching;

  @override
  Widget build(BuildContext context) {
    // ListView необходим для RefreshIndicator (нужен scrollable child).
    // Pull-to-refresh обрабатывает parent-RefreshIndicator; отдельной
    // кнопки «обновить» намеренно нет (swipe-gesture даже на empty
    // state работает через AlwaysScrollableScrollPhysics).
    final l = NsgL10n.of(context);
    final text = searching ? l.chatsListSearchEmpty : l.chatsListEmpty;
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Center(
          child: Text(text, style: Theme.of(context).textTheme.titleMedium),
        ),
      ],
    );
  }
}

class _ErrorEmpty extends StatelessWidget {
  const _ErrorEmpty({required this.error, required this.onRetry});

  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(
            NsgL10n.of(context).chatsListLoadFailed,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            '$error',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: onRetry,
            child: Text(NsgL10n.of(context).commonRetry),
          ),
        ],
      ),
    );
  }
}
