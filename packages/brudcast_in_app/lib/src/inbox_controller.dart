import 'dart:async';

import 'package:brudcast_flutter/module.dart';
import 'package:flutter/foundation.dart';

import 'in_app.dart';
import 'models.dart';

/// Pages through the inbox and follows its unread count, for an inbox screen built in Flutter.
///
/// Listen to it with a `ListenableBuilder`. Call [loadMore] when the list nears its end, and
/// [refresh] on pull to refresh. [markRead] and [delete] update the list at once and tell the
/// service.
class InboxController extends ChangeNotifier {
  /// Creates a controller and loads the first page.
  ///
  /// [pageSize] is how many entries each page holds, up to 100. Pass [inbox] in tests; the SDK's
  /// inbox is used otherwise.
  InboxController({BrudcastInbox? inbox, this.pageSize = 20}) : _inbox = inbox ?? BrudcastInApp.instance.inbox {
    _unread = _inbox.unreadCount;
    _unread.addListener(notifyListeners);
    unawaited(refresh());
  }

  final BrudcastInbox _inbox;
  late final ValueListenable<int> _unread;
  List<BrudcastInAppMessage> _messages = const [];
  bool _hasMore = true;
  bool _isLoading = false;
  BrudcastInboxException? _error;
  int _generation = 0;
  bool _disposed = false;

  /// How many entries each page holds.
  final int pageSize;

  /// The entries loaded so far, newest first.
  List<BrudcastInAppMessage> get messages => List.unmodifiable(_messages);

  /// Whether older entries remain to load.
  bool get hasMore => _hasMore;

  /// Whether a page is loading.
  bool get isLoading => _isLoading;

  /// Why the last load failed, or null after a load that worked.
  BrudcastInboxException? get error => _error;

  /// The number of unread entries in the whole inbox.
  int get unreadCount => _unread.value;

  /// Reloads the newest page, replacing what was loaded.
  Future<void> refresh() => _load(before: null);

  /// Loads the next older page, unless one is loading or none remain.
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore || _messages.isEmpty) return;
    await _load(before: _messages.last.createdAt);
  }

  /// Marks an entry read, in the list at once and then on every device.
  Future<void> markRead(BrudcastInAppMessage message) async {
    final index = _messages.indexWhere((entry) => entry.id == message.id);
    if (index < 0 || _messages[index].isRead) return;
    _messages = List.of(_messages)..[index] = _messages[index].markedRead();
    notifyListeners();
    await _inbox.markRead(message.id);
  }

  /// Deletes an entry, from the list at once and then on every device.
  Future<void> delete(BrudcastInAppMessage message) async {
    final before = _messages.length;
    _messages = _messages.where((entry) => entry.id != message.id).toList(growable: false);
    if (_messages.length == before) return;
    notifyListeners();
    await _inbox.delete(message.id);
  }

  Future<void> _load({required DateTime? before}) async {
    if (_isLoading && before != null) return;
    final generation = ++_generation;
    _isLoading = true;
    _notify();
    try {
      final page = await _inbox.list(before: before, limit: pageSize);
      if (generation != _generation) return;
      final known = before == null ? <String>{} : _messages.map((entry) => entry.id).toSet();
      final fresh = page.messages.where((entry) => !known.contains(entry.id));
      _messages = before == null ? fresh.toList(growable: false) : [..._messages, ...fresh];
      _hasMore = page.hasMore;
      _error = null;
    } on BrudcastInboxException catch (error) {
      if (generation != _generation) return;
      BrudcastLog.warning('The inbox failed to load: $error');
      _error = error;
    } finally {
      if (generation == _generation) {
        _isLoading = false;
        _notify();
      }
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _unread.removeListener(notifyListeners);
    super.dispose();
  }
}
