import 'messages.g.dart';
import 'models.dart';

/// Converts a message from the channel.
BrudcastInAppMessage messageFromPlatform(PlatformInAppMessage message) => BrudcastInAppMessage(
  id: message.id,
  campaignId: message.campaignId,
  format: switch (message.format) {
    PlatformMessageFormat.modal => BrudcastMessageFormat.modal,
    PlatformMessageFormat.banner => BrudcastMessageFormat.banner,
    PlatformMessageFormat.fullscreen => BrudcastMessageFormat.fullscreen,
    PlatformMessageFormat.inboxOnly => BrudcastMessageFormat.inboxOnly,
  },
  isTest: message.isTest,
  title: message.title,
  preview: message.preview,
  thumbnailUrl: message.thumbnailUrl == null ? null : Uri.tryParse(message.thumbnailUrl!),
  isRead: message.isRead,
  createdAt: DateTime.fromMillisecondsSinceEpoch(message.createdAtMillis),
  design: message.design,
);

/// Converts a decision for the channel.
PlatformMessageDecision decisionToPlatform(BrudcastMessageDecision decision) => switch (decision) {
  BrudcastMessageDecision.show => PlatformMessageDecision.show,
  BrudcastMessageDecision.suppress => PlatformMessageDecision.suppress,
  BrudcastMessageDecision.defer => PlatformMessageDecision.deferred,
  BrudcastMessageDecision.custom => PlatformMessageDecision.custom,
};
