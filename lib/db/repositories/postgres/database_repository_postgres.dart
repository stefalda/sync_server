import 'package:postgres/postgres.dart';
import 'package:sync_server/db/models/data.dart';
import 'package:sync_server/db/models/user.dart';
import 'package:sync_server/db/models/user_client.dart';
import 'package:sync_server/db/repositories/database_repository_abstract.dart';
import 'package:sync_server/shared/models/sync_data.dart';

class DatabaseRepositoryPostgres extends DatabaseRepositoryAbstract {
  PostgreSQLConnection connection = PostgreSQLConnection(
      "bare-mantis-6973.7tc.cockroachlabs.cloud", 26257, "sync_server",
      username: "stefano", password: "VtS4JGVf_1yB8CJ9V6lvHg");

  static final DatabaseRepositoryPostgres _singleton =
      DatabaseRepositoryPostgres._internal();
  factory DatabaseRepositoryPostgres() {
    return _singleton;
  }

  DatabaseRepositoryPostgres._internal();

  /// Restituisce una connessione aperta
  Future<PostgreSQLConnection> getConnection() async {
    if (connection.isClosed) {
      await connection.open();
    }
    return connection;
  }

  @override
  Future<void> openTheDB(String realm) async {
    await connection.open();
  }

  @override
  Future<void> closeTheDB(String realm) async {
    await connection.close();
  }

  @override
  Future<void> deleteClient(int userId, String client,
      {required String realm}) {
    // TODO: implement deleteClient
    throw UnimplementedError();
  }

  @override
  Future<void> deleteUserData(int userid, {required String realm}) {
    // TODO: implement deleteUserData
    throw UnimplementedError();
  }

  @override
  Future<Data?> getRowData(String rowguid, {required String realm}) {
    // TODO: implement getRowData
    throw UnimplementedError();
  }

  @override
  Future<String> getRowDataValue(String rowguid, {required String realm}) {
    // TODO: implement getRowDataValue
    throw UnimplementedError();
  }

  @override
  Future<List<SyncData>> getServerChanges(
      {required int userid, required int since, required String realm}) {
    // TODO: implement getServerChanges
    throw UnimplementedError();
  }

  @override
  Future<List> getTableData(
      {required int userid,
      required String tablename,
      required String realm,
      String? additionalFilter}) {
    // TODO: implement getTableData
    throw UnimplementedError();
  }

  @override
  Future<User?> getUser(String email, String password,
      {required String realm}) {
    // TODO: implement getUser
    throw UnimplementedError();
  }

  @override
  Future<UserClient?> getUserClient(String clientId, {required String realm}) {
    // TODO: implement getUserClient
    throw UnimplementedError();
  }

  @override
  Future<UserClient?> getUserClientSyncingByUserIdAndNotClientId(
      userid, clientid,
      {required String realm}) {
    // TODO: implement getUserClientSyncingByUserIdAndNotClientId
    throw UnimplementedError();
  }

  @override
  Future setRowData(Data data, {required String realm}) {
    // TODO: implement setRowData
    throw UnimplementedError();
  }

  @override
  Future setSyncData(SyncData syncData, {required String realm}) {
    // TODO: implement setSyncData
    throw UnimplementedError();
  }

  @override
  Future setUser(User user, {required String realm}) {
    // TODO: implement setUser
    throw UnimplementedError();
  }

  @override
  Future setUserClient(UserClient userClient, {required String realm}) {
    // TODO: implement setUserClient
    throw UnimplementedError();
  }
}
