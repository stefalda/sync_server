import 'package:sync_server/db/models/user_token.dart';
import 'package:sync_server/db/repositories/authentication_repository_abstract.dart';
import 'package:sync_server/db/repositories/postgres/database_repository_postgres.dart';

class AuthenticationRepositoryPostgres
    implements AuthenticationRepositoryAbstract {
  @override
  Future<bool> checkClientId(
      {required String email,
      required String password,
      required String clientId,
      required String realm}) {
    // TODO: implement checkClientId
    throw UnimplementedError();
  }

  @override
  Future<UserToken?> getToken(
      {required String token, required String realm}) async {
    final connection = await DatabaseRepositoryPostgres().getConnection();
    final String sql =
        "SELECT clientid, token, refreshtoken, lastrefresh FROM ${UserToken.table} WHERE token = @token";
    List<Map<String, Map<String, dynamic>>> results = await connection
        .mappedResultsQuery(sql, substitutionValues: {"token": token});
    if (results.isEmpty) return null;
    Map<String, Map<String, dynamic>> row = results.first;
    return UserToken.fromMap(row);
  }

  @override
  Future<UserToken?> getTokenFromRefreshToken(
      {required String refreshToken, required String realm}) {
    // TODO: implement getTokenFromRefreshToken
    throw UnimplementedError();
  }

  @override
  Future<int> getUserIdFromToken(
      {required String token, required String realm}) {
    // TODO: implement getUserIdFromToken
    throw UnimplementedError();
  }

  @override
  Future<void> updateToken(
      {required UserToken userToken, required String realm}) {
    // TODO: implement updateToken
    throw UnimplementedError();
  }
}
