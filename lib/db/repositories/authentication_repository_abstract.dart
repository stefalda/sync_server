import 'package:sync_server/db/models/user_token.dart';

/// Abstract class to support both sqlite and postgres
abstract class AuthenticationRepositoryAbstract {
  /// Return the token
  Future<UserToken?> getToken({required String token, required String realm});

  /// Return the refresh token
  Future<UserToken?> getTokenFromRefreshToken(
      {required String refreshToken, required String realm});

  /// Return the userId for the token
  Future<int> getUserIdFromToken(
      {required String token, required String realm});

  /// Update token
  Future<void> updateToken(
      {required UserToken userToken, required String realm});

  /// Check the client id
  Future<bool> checkClientId(
      {required String email,
      required String password,
      required String clientId,
      required String realm});
}
