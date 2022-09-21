// ignore: depend_on_referenced_packages
import 'package:args/args.dart';
import 'package:shelf_plus/shelf_plus.dart';
import 'package:sync_server/db/database_repository.dart';

import 'middleware.dart';
import 'routes/login.dart';
import 'routes/registration.dart';
import 'routes/sync.dart';
import 'routes/table_data.dart';
import 'routes/websocket.dart';

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

Middleware middleware = getMiddleware();

Handler init() {
  var app = Router().plus;
  //app.use(middleware);
  app.get('/', () => 'Hello from your sync server!');

  handleLoginRoutes(app, middleware);
  handleRegistrationRoutes(app, middleware);
  handleSyncRoutes(app, middleware);
  handleTableDataRoutes(app, middleware);
  //TODO
  handleWebSocket(app);
  return app;
}
