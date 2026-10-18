import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'heights.dart';
import 'in_app.dart';
import 'models.dart';

/// An inbox entry drawn by the native renderer, exactly as the SDK draws messages, with its
/// buttons working.
///
/// It sizes itself to the height the design needs at the width it is given, so it can sit in a
/// scroll view; pass [expand] to fill the space given instead, scrolling inside when the design is
/// taller. The entry must come from `Brudcast.inApp.inbox.list` or an [InboxController]. When its
/// design cannot be drawn by this SDK version, it draws nothing.
///
/// Each one is a platform view, which is costly on Android in long lists. Use it for a detail
/// screen, and plain Flutter tiles from [BrudcastInAppMessage.title],
/// [BrudcastInAppMessage.preview] and [BrudcastInAppMessage.thumbnailUrl] for the list.
class BrudcastInboxMessage extends StatefulWidget {
  /// Draws [message].
  const BrudcastInboxMessage({super.key, required this.message, this.expand = false});

  /// The inbox entry.
  final BrudcastInAppMessage message;

  /// Whether to fill the space given instead of sizing to the design.
  final bool expand;

  @override
  State<BrudcastInboxMessage> createState() => _BrudcastInboxMessageState();
}

class _BrudcastInboxMessageState extends State<BrudcastInboxMessage> {
  static const String _viewType = 'com.brudcast.flutter/inbox_message';

  double? _height;
  int? _viewId;

  @override
  void initState() {
    super.initState();
    ensureInAppReceiver();
  }

  @override
  void dispose() {
    final viewId = _viewId;
    if (viewId != null) inboxMessageHeightListeners.remove(viewId);
    super.dispose();
  }

  void _created(int viewId) {
    _viewId = viewId;
    inboxMessageHeightListeners[viewId] = (height) {
      if (mounted && height != _height) setState(() => _height = height);
    };
  }

  @override
  Widget build(BuildContext context) {
    final params = <String, Object?>{'messageId': widget.message.id};
    final Widget view = switch (defaultTargetPlatform) {
      TargetPlatform.android => AndroidView(
        key: ValueKey(widget.message.id),
        viewType: _viewType,
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _created,
        gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
      ),
      TargetPlatform.iOS => UiKitView(
        key: ValueKey(widget.message.id),
        viewType: _viewType,
        creationParams: params,
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _created,
      ),
      _ => const SizedBox.shrink(),
    };
    if (widget.expand) return view;
    return SizedBox(height: _height ?? 1, child: view);
  }
}
