import 'package:shelf_plus/shelf_plus.dart';
import 'package:sync_server/db/authentication_repository.dart';
import 'package:sync_server/db/database_repository.dart';

import '../authentication_helper.dart';

handleTableDataRoutes(app, middleware) {
  /// Get table data
  /// TODO - TEST
  /// FIXME - Pass the userid
  app.get(
    '/data/<realm>/<table>',
    (Request request) async {
      final String realm = request.routeParameter('realm');
      final String table = request.routeParameter('table');
      final String token =
          AuthenticationHelper.tokenAuthenticationData(request)!;
      final int userid = await AuthenticationRepository.getUserIdFromToken(
          token: token, realm: realm);
      final json = await DatabaseRepository()
          .getTableData(userid: userid, tablename: table, realm: realm);
      return Response.ok(json.toString());
    },
    use: middleware,
  );
}
