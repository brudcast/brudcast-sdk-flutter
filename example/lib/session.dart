import 'package:brudcast_flutter/brudcast_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The signed-in user, kept across launches the way an app keeps its login. The SDK keeps its own
/// identity too, so a relaunch needs no new `identify`.
final class SampleSession extends ChangeNotifier {
  SampleSession._(this._preferences);

  static const String _externalIdKey = 'sample.externalId';
  static const String _emailKey = 'sample.email';

  final SharedPreferences _preferences;

  /// Loads the saved session.
  static Future<SampleSession> load() async => SampleSession._(await SharedPreferences.getInstance());

  /// The signed-in user's id, or null when signed out.
  String? get externalId => _preferences.getString(_externalIdKey);

  /// The signed-in user's email.
  String? get email => _preferences.getString(_emailKey);

  /// Whether someone is signed in.
  bool get isSignedIn => externalId != null;

  /// Signs a user in: identifies them to Brudcast with the hash the backend computed.
  Future<void> signIn({required String externalId, required String userHash, String? email}) async {
    await Brudcast.identify(
      externalId,
      userHash: userHash,
      traits: BrudcastTraits(email: email),
    );
    await _preferences.setString(_externalIdKey, externalId);
    if (email == null) {
      await _preferences.remove(_emailKey);
    } else {
      await _preferences.setString(_emailKey, email);
    }
    notifyListeners();
  }

  /// Signs the user out: Brudcast forgets them, and their push token stops reaching them here.
  Future<void> signOut() async {
    await Brudcast.reset();
    await _preferences.remove(_externalIdKey);
    await _preferences.remove(_emailKey);
    notifyListeners();
  }
}
