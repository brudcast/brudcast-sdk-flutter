/// Push notifications for the Brudcast Flutter SDK: permission, the FCM token, the notification
/// handler, and open tracking that needs no Dart code.
///
/// Add [BrudcastPush.module] to `BrudcastOptions.modules`, then use `Brudcast.push`.
library;

export 'src/models.dart';
export 'src/push.dart' show BrudcastPush, BrudcastPushAccess;
