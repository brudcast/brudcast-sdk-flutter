import 'dart:convert';

import 'package:http/http.dart' as http;

/// What the backend returns at sign-in, ready for `Brudcast.identify`.
final class SignedIn {
  /// Creates a sign-in result.
  const SignedIn({required this.externalId, required this.userHash, this.email});

  /// The user's id in the app, which Brudcast calls the external id.
  final String externalId;

  /// `hex(HMAC-SHA256(identitySecret, externalId))`, computed by the backend.
  final String userHash;

  /// The user's email.
  final String? email;
}

/// The app's own backend, which signs users in and holds what the app must never contain: the
/// identity secret and the Brudcast API key. The README lists the endpoints it needs.
final class SampleBackend {
  /// Talks to the backend at [baseUrl], such as `http://10.0.2.2:4000` for one on the host.
  SampleBackend(this.baseUrl, {http.Client? client}) : _client = client ?? http.Client();

  /// The backend's URL.
  final String baseUrl;

  final http.Client _client;

  /// Signs a user in. The backend computes the user hash with the identity secret.
  Future<SignedIn> login(String userId, String? email) async {
    final response = await _post('/login', {'userId': userId, 'email': email});
    return SignedIn(
      externalId: response['externalId'] as String,
      userHash: response['userHash'] as String,
      email: response['email'] as String?,
    );
  }

  /// Asks the backend to send the user a welcome in-app message through the Brudcast API.
  Future<void> sendWelcome(String externalId) => _post('/welcome', {'externalId': externalId});

  Future<Map<String, Object?>> _post(String path, Map<String, Object?> body) async {
    final uri = Uri.parse(baseUrl.replaceAll(RegExp(r'/+$'), '') + path);
    final response = await _client
        .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    final decoded = response.body.trim().isEmpty
        ? <String, Object?>{}
        : jsonDecode(response.body) as Map<String, Object?>;
    if (response.statusCode < 200 || response.statusCode > 299) {
      throw SampleBackendException(decoded['message'] as String? ?? 'HTTP ${response.statusCode}');
    }
    return decoded;
  }
}

/// The backend refused or could not be reached.
final class SampleBackendException implements Exception {
  /// Creates an exception.
  const SampleBackendException(this.message);

  /// What went wrong, from the backend's `message`.
  final String message;

  @override
  String toString() => message;
}
