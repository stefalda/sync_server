import 'dart:convert';

import 'package:shelf_plus/shelf_plus.dart';
import 'package:sync_server/db/models/user_token.dart';
import 'package:uuid/uuid.dart';

import '../authentication_helper.dart';

const tokenDurationInSeconds = 3600;

class Token {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final DateTime expiresOn;

  Token(
      {required this.accessToken,
      required this.refreshToken,
      required this.expiresOn,
      this.expiresIn = tokenDurationInSeconds});

  Map<String, dynamic> toJson() {
    return {
      "token_type": "Bearer",
      "access_token": accessToken,
      "expires_in": expiresIn,
      "expires_on": expiresOn.millisecondsSinceEpoch,
      "refresh_token": refreshToken
    };
  }

  factory Token.fromUserToken(UserToken userToken) {
    return Token(
        accessToken: userToken.token,
        refreshToken: userToken.refreshToken,
        expiresOn: userToken.lastRefresh
            .add(Duration(seconds: tokenDurationInSeconds)));
  }
}

handleLoginRoutes(app, middleware) {
  /// Return a TOKEN, REFRESH TOKEN
  /// body: {"clientId":"XXXXXX"}
  app.post(
    '/login/<realm>',
    (Request request) async {
      final simpleAuthentication =
          AuthenticationHelper.simpleAuthenticationData(request);
      dynamic body;
      try {
        body = await request.body.asJson;
      } catch (ex) {
        return Response.badRequest(
            body: {'message': 'Missing body data'}.toString());
      }

      final clientId = body['clientid'];
      final realm = request.routeParameter('realm');

      // Verify that simpleauthentication data and clientid match
      final bool check = await AuthenticationHelper.authenticationRepository
          .checkClientId(
              email: simpleAuthentication!.username,
              password: simpleAuthentication.password,
              clientId: clientId,
              realm: realm);
      if (!check) {
        return Response.forbidden({
          'message': 'Invalid clientid for current username and password'
        }.toString());
      }

      //Register on the DB the new TOKEN
      UserToken userToken = UserToken();
      userToken.token = Uuid().v4();
      userToken.refreshToken = Uuid().v4();
      userToken.lastRefresh = DateTime.now();
      userToken.clientId = clientId;
      await AuthenticationHelper.authenticationRepository
          .updateToken(userToken: userToken, realm: realm);
      final token = Token.fromUserToken(userToken);
      return Response.ok(jsonEncode(token.toJson()));
    },
    use: middleware,
  );

  /// Refresh token
  /// https://learn.microsoft.com/en-us/machine-learning-server/operationalize/how-to-manage-access-tokens
  /// {"refresh_token": 'saddsadsad'}
  app.post('/login/<realm>/refreshToken', (Request request) async {
    final refreshTokenData = await request.body.asJson;
    final refreshToken = refreshTokenData['refresh_token'];
    final realm = request.routeParameter('realm');
    //  Verify RefreshToken
    final userToken = await AuthenticationHelper.authenticationRepository
        .getTokenFromRefreshToken(refreshToken: refreshToken, realm: realm);
    if (userToken == null) {
      return Response.forbidden(
          {'message': 'Invalid refresh token, please relogin'}.toString());
    }
    // Register on the DB the new TOKEN
    userToken.token = Uuid().v4();
    userToken.refreshToken = Uuid().v4();
    userToken.lastRefresh = DateTime.now();
    await AuthenticationHelper.authenticationRepository
        .updateToken(userToken: userToken, realm: realm);
    final token = Token.fromUserToken(userToken);
    return Response.ok(jsonEncode(token.toJson()));
  });
}
