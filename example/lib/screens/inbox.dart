import 'package:brudcast_in_app/brudcast_in_app.dart';
import 'package:flutter/material.dart';

import '../router.dart';

/// An inbox built in Flutter with [InboxController]: plain tiles for the list, paging as it
/// scrolls, pull to refresh, swipe to delete.
class InboxScreen extends StatefulWidget {
  /// Creates the screen.
  const InboxScreen({super.key});

  @override
  State<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends State<InboxScreen> {
  final _controller = InboxController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) => Text(_controller.unreadCount == 0 ? 'Inbox' : 'Inbox (${_controller.unreadCount})'),
      ),
    ),
    body: ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final messages = _controller.messages;
        if (messages.isEmpty) {
          return Center(
            child: _controller.isLoading
                ? const CircularProgressIndicator()
                : Text(_controller.error == null ? 'No messages yet' : 'The inbox could not load'),
          );
        }
        return RefreshIndicator(
          onRefresh: _controller.refresh,
          child: ListView.separated(
            itemCount: messages.length + (_controller.hasMore ? 1 : 0),
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              if (index == messages.length) {
                _controller.loadMore();
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final message = messages[index];
              return Dismissible(
                key: ValueKey(message.id),
                direction: DismissDirection.endToStart,
                background: ColoredBox(color: Theme.of(context).colorScheme.errorContainer),
                onDismissed: (_) => _controller.delete(message),
                child: _InboxTile(
                  message: message,
                  onTap: () {
                    _controller.markRead(message);
                    Navigator.of(context).pushNamed(Routes.inboxMessage, arguments: message);
                  },
                ),
              );
            },
          ),
        );
      },
    ),
  );
}

class _InboxTile extends StatelessWidget {
  const _InboxTile({required this.message, required this.onTap});

  final BrudcastInAppMessage message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final thumbnail = message.thumbnailUrl;
    return ListTile(
      onTap: onTap,
      leading: thumbnail == null
          ? null
          : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                thumbnail.toString(),
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const SizedBox(width: 40),
              ),
            ),
      title: Text(
        message.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontWeight: message.isRead ? FontWeight.normal : FontWeight.w600),
      ),
      subtitle: Text(message.preview, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: message.isRead ? null : Icon(Icons.circle, size: 10, color: Theme.of(context).colorScheme.primary),
    );
  }
}

/// One inbox entry, drawn by the native renderer with [BrudcastInboxMessage].
class InboxMessageScreen extends StatelessWidget {
  /// Creates the screen. The route's argument is the entry.
  const InboxMessageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final message = ModalRoute.of(context)!.settings.arguments! as BrudcastInAppMessage;
    return Scaffold(
      appBar: AppBar(title: Text(message.title)),
      body: BrudcastInboxMessage(message: message, expand: true),
    );
  }
}
