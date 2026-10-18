import 'log.dart';

/// Keeps the property values the Brudcast API accepts: strings, finite numbers, booleans and nulls.
/// Anything else is dropped with a warning before it crosses the channel.
Map<String, Object?> brudcastProperties(Map<String, Object?> properties) {
  final accepted = <String, Object?>{};
  properties.forEach((key, value) {
    if (value == null || value is String || value is bool) {
      accepted[key] = value;
    } else if (value is num) {
      if (value.isFinite) {
        accepted[key] = value;
      } else {
        BrudcastLog.warning('Property "$key" is $value, which JSON cannot carry; it is dropped');
      }
    } else {
      BrudcastLog.warning(
        'Property "$key" is a ${value.runtimeType}, not a string, number, boolean or null; it is dropped',
      );
    }
  });
  return accepted;
}
