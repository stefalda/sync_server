import 'package:sqlite_wrapper/sqlite_wrapper.dart';
import 'package:sync_server/db/models/user.dart';
import 'package:sync_server/db/models/user_client.dart';
import 'package:sync_server/db/models/user_token.dart';
import 'package:sync_server/db/repositories/authentication_repository_abstract.dart';
import 'package:sync_server/db/repositories/repositories.dart';

class AuthenticationRepository implements AuthenticationRepositoryAbstract {
  /// Return the token
  @override
  Future<UserToken?> getToken(
      {required String token, required String realm}) async {
    // Check that the DB is opened
    await getDatabaseRepository().openTheDB(realm);
    final String sql =
        "SELECT clientid, token, refreshtoken, lastrefresh FROM ${UserToken.table} WHERE token = ?";
    return await SQLiteWrapper().query(sql,
        dbName: realm,
        params: [token],
        singleResult: true,
        fromMap: UserToken.fromMap);
  }

  /// Return the refresh token
  @override
  Future<UserToken?> getTokenFromRefreshToken(
      {required String refreshToken, required String realm}) async {
    // Check that the DB is opened
    await getDatabaseRepository().openTheDB(realm);
    final String sql =
        "SELECT clientid, token, refreshtoken, lastrefresh FROM ${UserToken.table} WHERE refreshtoken = ?";
    return await SQLiteWrapper().query(sql,
        dbName: realm,
        params: [refreshToken],
        singleResult: true,
        fromMap: UserToken.fromMap);
  }

  /// Return the userId for the token
  @override
  Future<int> getUserIdFromToken(
      {required String token, required String realm}) async {
    // Check that the DB is opened
    await getDatabaseRepository().openTheDB(realm);

    final String sql =
        """SELECT uc.userid FROM ${UserClient.table} uc INNER JOIN ${UserToken.table} ut ON 
                  uc.clientid = ut.clientid WHERE ut.token = ?
                  """;
    return await SQLiteWrapper()
        .query(sql, dbName: realm, params: [token], singleResult: true);
  }

  /// Update token
  @override
  Future<void> updateToken(
      {required UserToken userToken, required String realm}) async {
    // Check that the DB is opened
    await getDatabaseRepository().openTheDB(realm);

    await SQLiteWrapper().save(userToken.toMap(), UserToken.table,
        dbName: realm, keys: ['clientid']);
  }

  @override
  Future<bool> checkClientId(
      {required String email,
      required String password,
      required String clientId,
      required String realm}) async {
    // Check that the DB is opened
    await getDatabaseRepository().openTheDB(realm);

    final sql =
        """SELECT u.password, u.salt FROM ${UserClient.table} uc INNER JOIN ${User.table} u on u.id = uc.userid WHERE 
              u.email = ? and uc.clientid=?
    """;
    final result = await SQLiteWrapper().query(sql,
        dbName: realm, params: [email, clientId], singleResult: true);
    if (result == null) return false;
    return result['password'] ==
        getDatabaseRepository().encryptPassword(password, result['salt']);
  }
}
