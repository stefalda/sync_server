import 'dart:convert';

import 'package:shelf_plus/shelf_plus.dart';
import 'package:sync_server/api/models/client_changes.dart';
import 'package:sync_server/api/sync_helper.dart';
import 'package:sync_server/db/models/user_token.dart';

import '../authentication_helper.dart';

handleSyncRoutes(app, middleware) {
  // /sync
  /// Pull method called by the client before pushing its data
  /// pathParams:
  ///   realm - the realm of the data i.e. the Application but could be a sharedList
  /// params:
  ///   clientid - the client identifier
  ///   lastsync - last sync date in milliseconds since Epoch
  /// body:
  ///   clientChanges - a list of SyncData that the client "propose"
  /// return:
  ///   SyncDetails - a list of changes from the server and a list of rowguid
  ///           that must be considered outdated and discarded from the client
  ///
  app.post('/pull/<realm>', (Request request) async {
    final String realm = request.routeParameter('realm');
    final UserToken? userToken =
        await AuthenticationHelper.getUserTokenFromRequest(request);
    print("\n/pull for $realm");
    final json = await request.body.asJson;
    print("\n/pull $json\n\n-----------------------------------------------\n");
    final ClientChanges clientChanges = ClientChanges.fromMap(await json);
    if (clientChanges.clientId != userToken?.clientId) {
      return Response.badRequest(body: {
        'message': 'Data ClientId is not compatible with token clientId'
      });
    }
    final res = jsonEncode(await SyncHelper.pull(
        clientid: clientChanges.clientId,
        lastSync: clientChanges.lastSync,
        clientChanges: clientChanges.changes,
        realm: realm));
    print(res);
    return res;
  }, use: middleware);

  /// Push method called by the client to send its data changes to the server
  /// params:
  ///   clientid - the client identifier
  ///   lastsync - last sync date in milliseconds since Epoch
  /// body:
  ///   clientChanges - a list of SyncData changes made on the client and that
  ///     must be persisted on the server
  /// return:
  ///   SyncInfo - a date (lastSync) to be stored on the client
  ///
  app.post('/push/<realm>', (Request request) async {
    final String realm = request.routeParameter('realm');
    final UserToken? userToken =
        await AuthenticationHelper.getUserTokenFromRequest(request);
    print("/push to $realm ");
    final json = await request.body.asJson;
    print("\n/push $json\n\n-----------------------------------------------\n");

    final ClientChanges clientChanges = ClientChanges.fromMap(json);
    // Check the token and the clientId
    if (clientChanges.clientId != userToken?.clientId) {
      return Response.badRequest(body: {
        'message': 'Data ClientId is not compatible with token clientId'
      });
    }

    return jsonEncode(await SyncHelper.push(
        clientid: clientChanges.clientId,
        lastSync: clientChanges.lastSync,
        clientChanges: clientChanges.changes,
        realm: realm));
  }, use: middleware);
}
