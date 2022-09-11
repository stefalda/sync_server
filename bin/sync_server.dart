import 'dart:convert';

// ignore: depend_on_referenced_packages
import 'package:args/args.dart';
import 'package:shelf_plus/shelf_plus.dart';
import 'package:sync_server/api/models/client_changes.dart';
import 'package:sync_server/api/models/user_registration.dart';
import 'package:sync_server/api/sync_helper.dart';
import 'package:sync_server/api/users_helper.dart';
import 'package:sync_server/db/database_repository.dart';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption("host",
        defaultsTo: "0.0.0.0", help: "Server address, default to localhost")
    ..addOption("port",
        defaultsTo: "8080", help: "Server port, default to 8080")
    ..addOption("dbPath",
        help:
            "Set the folder where the databases can be read and written according to the user permissions");
  ArgResults argResults = parser.parse(arguments);
  final int port = int.parse(argResults["port"]);
  final String host = argResults["host"];
  if (argResults['dbPath'] != null) {
    DatabaseRepository().setBasePath(argResults['dbPath']);
  }
  shelfRun(init,
      defaultBindAddress: host,
      defaultBindPort: port,
      defaultEnableHotReload: false);
}

Handler init() {
  var app = Router().plus;

  app.get('/', () => 'Hello from your sync server!');

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
    print("\n/pull for $realm");
    final json = await request.body.asJson;
    print("\n/pull $json\n\n-----------------------------------------------\n");
    final ClientChanges clientChanges = ClientChanges.fromMap(await json);
    final res = jsonEncode(await SyncHelper.pull(
        clientid: clientChanges.clientId,
        lastSync: clientChanges.lastSync,
        clientChanges: clientChanges.changes,
        realm: realm));
    print(res);
    return res;
  });

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
    print("/push to $realm ");
    final json = await request.body.asJson;
    print("\n/push $json\n\n-----------------------------------------------\n");

    final ClientChanges clientChanges = ClientChanges.fromMap(json);
    return jsonEncode(await SyncHelper.push(
        clientid: clientChanges.clientId,
        lastSync: clientChanges.lastSync,
        clientChanges: clientChanges.changes,
        realm: realm));
  });

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
    } catch (exception) {
      // Error loggin in...
      return Response.internalServerError(body: exception.toString());
    }
    return Response.ok(
        jsonEncode({'message': 'User and Client registered successfully!'}));
  });

  /// Delete ALL user data
  /// BEWARE: it can't be undone
  app.post('/unregister/<realm>', (Request request) async {
    final String realm = request.routeParameter('realm');
    print("unregister from $realm");
    final UserRegistration userRegistration =
        UserRegistration.fromMap(await request.body.asJson);
    await UserHelper().unregister(userRegistration, realm: realm);
    return Response.ok(
        jsonEncode({'message': "User and Client unregistered successfully!"}));
  });

  /// Get table data
  /// TODO - TEST
  /// FIXME - Pass the userid
  app.get('/data/<realm>/<table>', (Request request) async {
    final String realm = request.routeParameter('realm');
    final String table = request.routeParameter('table');
    // final String userid = request.headers.values('sdad');
    final json = await DatabaseRepository()
        .getTableData(userid: 8, tablename: table, realm: realm);
    return Response.ok(jsonEncode(json));
  });

  /// TODO --- Web socket implementation
/*
  // Track connected clients
  var wsSessions = <WebSocketSession>[];

// Web socket route
  app.get(
    '/ws',
    () => WebSocketSession(
      onOpen: (ws) {
        // Join chat
        wsSessions.add(ws);
        wsSessions
            .where((user) => user != ws)
            .forEach((user) => user.send('A new user joined the chat.'));
      },
      onClose: (ws) {
        // Leave chat
        wsSessions.remove(ws);
        for (var user in wsSessions) {
          user.send('A user has left.');
        }
      },
      onMessage: (ws, dynamic data) {
        // Deliver messages to all users
        for (var user in wsSessions) {
          user.send(data);
        }
      },
    ),
  );
  */
  return app;
}
