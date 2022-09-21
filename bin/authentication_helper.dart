import 'dart:convert';

import 'package:shelf_plus/shelf_plus.dart';
import 'package:sync_server/db/authentication_repository.dart';
import 'package:sync_server/db/database_repository.dart';
import 'package:sync_server/db/models/user_token.dart';

class SimpleAuthentication {
  final String username;
  final String password;

  SimpleAuthentication(this.username, this.password);
}

class TokenAuthentication {
  final String token;
  String? refreshToken;

  TokenAuthentication(this.token, {this.refreshToken});
}

class AuthenticationHelper {
  /// Extract the username and password from the simpleauthenticated request
  static SimpleAuthentication? simpleAuthenticationData(Request request) {
    try {
      final String authorization = request.headers['authorization']!;
      String decoded = utf8.decode(base64.decode((authorization.substring(6))));
      List<String> splitData = decoded.split(":");
      return SimpleAuthentication(splitData[0], splitData[1]);
    } catch (ex) {
      print("Wrong authorization format ${request.headers['authorization']!}");
    }
    return null;
  }

  /// Extract the username and password from the bearer tocken request
  static String? tokenAuthenticationData(Request request) {
    try {
      final String authorization = request.headers['authorization']!;
      return authorization.substring(7);
    } catch (ex) {
      print("Wrong authorization format ${request.headers['authorization']!}");
    }
    return null;
  }

  /// Return null if can proceed or 403 if username or password are wrong
  static Future<Response?> checkSimpleAuthentication(Request request) async {
    final String? authorization = request.headers['authorization'];
    if (authorization == null) {
      return Response.forbidden(
          {'message': 'Missing basic authentication'}.toString());
    }
    final simpleAuthentication = simpleAuthenticationData(request);
    if (simpleAuthentication == null) {
      return Response.forbidden(
          {'message': 'Missing username or password'}.toString());
    }
    String realm = request.routeParameter("realm");
    // Check the db
    final user = await DatabaseRepository().getUser(
        simpleAuthentication.username, simpleAuthentication.password,
        realm: realm);
    if (user == null) {
      return Response.forbidden(
          {'message': 'Wrong username or password'}.toString());
    }
    return null;
  }

  /// Return null if can proceed or 403 if username or password are wrong
  static Future<Response?> checkBearerAuthentication(Request request) async {
    // Authorization: Bearer <token>
    final String? authorization = request.headers['authorization'];
    if (authorization == null) {
      return Response.forbidden({'message': 'Missing bearer token'}.toString());
    }
    // Empty Token
    String? token = tokenAuthenticationData(request);
    if (token == null) {
      return Response.forbidden({'message': 'Missing bearer token'}.toString());
    }
    // Get the token data from the DB
    String realm = request.routeParameter("realm");
    final userToken =
        await AuthenticationRepository.getToken(token: token, realm: realm);
    // Unknown token
    if (userToken == null) {
      return Response.forbidden({'message': 'Wrong token'}.toString());
    }
    // Token expired
    if (userToken.isExpired) {
      return Response(400, body: {'message': 'Token has expired'}.toString());
    }
    // Can access...
    return null;
  }

  /// Get the UserToken from the DB starting with the token in the request
  static Future<UserToken?> getUserTokenFromRequest(Request request) async {
    final String realm = request.routeParameter('realm');
    final String token = AuthenticationHelper.tokenAuthenticationData(request)!;
    return await AuthenticationRepository.getToken(token: token, realm: realm);
  }
}
