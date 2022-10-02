import 'dart:convert';

import 'package:shelf_plus/shelf_plus.dart';
import 'package:sync_server/api/models/user_registration.dart';
import 'package:sync_server/api/users_helper.dart';
import 'package:sync_server/db/models/user_token.dart';

import '../authentication_helper.dart';

handleRegistrationRoutes(app, middleware) {
  /// Register a user and a client or just a client
  /// if the user is already registered
  app.post('/register/<realm>', (Request request) async {
    final String realm = request.routeParameter('realm');
    print("register to $realm");
    final String body = await request.body.asString;
    final UserRegistration userRegistration =
        UserRegistration.fromMap(jsonDecode(body));
    try {
      await UserHelper().register(userRegistration, realm: realm);
    } on WrongPasswordException {
      return Response(401, body: "Wrong email or password");
    } on EmailConflictException {
      return Response(409,
          body: "The email is already registered, try to LOGIN instead...");
    } catch (exception) {
      // Error loggin in...
      return Response.internalServerError(body: exception.toString());
    }
    return Response.ok(jsonEncode({
      'message': 'User and Client registered successfully!',
      'user': userRegistration
    }));
  });

  /// Delete ALL user data
  /// BEWARE: it can't be undone
  app.post('/unregister/<realm>', (Request request) async {
    final String realm = request.routeParameter('realm');
    print("unregister from $realm");
    final UserToken? userToken =
        await AuthenticationHelper.getUserTokenFromRequest(request);
    final UserRegistration userRegistration =
        UserRegistration.fromMap(await request.body.asJson);
    if (userRegistration.clientId != userToken?.clientId) {
      return Response.badRequest(body: {
        'message': 'Data ClientId is not compatible with token clientId'
      });
    }
    await UserHelper().unregister(userRegistration, realm: realm);
    return Response.ok(
        jsonEncode({'message': "User and Client unregistered successfully!"}));
  }, use: middleware);
}
