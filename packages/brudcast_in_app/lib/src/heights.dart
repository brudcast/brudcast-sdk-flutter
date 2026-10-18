import 'package:flutter/foundation.dart';

/// The platform views waiting for the height their design needs, by platform view id.
final Map<int, ValueChanged<double>> inboxMessageHeightListeners = {};
