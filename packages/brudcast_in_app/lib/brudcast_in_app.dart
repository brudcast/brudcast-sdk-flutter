/// In-app messages and the inbox for the Brudcast Flutter SDK. Messages are drawn by the native
/// SDKs, the same way they are in native apps.
///
/// Add [BrudcastInApp.module] to `BrudcastOptions.modules`, then use `Brudcast.inApp`.
library;

export 'src/in_app.dart' show BrudcastInApp, BrudcastInAppAccess, BrudcastInbox;
export 'src/inbox_controller.dart';
export 'src/inbox_message.dart';
export 'src/models.dart';
