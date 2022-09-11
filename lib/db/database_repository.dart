//import 'package:path_provider/path_provider.dart';
import 'package:sqlite_wrapper/sqlite_wrapper.dart';
import 'package:sync_server/db/models/data.dart';
import 'package:sync_server/db/models/user.dart';
import 'package:sync_server/db/models/user_client.dart';
import 'package:sync_server/shared/models/sync_data.dart';

class DatabaseRepository {
  String _basePath = ".";

  static final DatabaseRepository _singleton = DatabaseRepository._internal();
  factory DatabaseRepository() {
    return _singleton;
  }

  DatabaseRepository._internal();

  ///Path where to store the databases
  setBasePath(String path) {
    _basePath = path;
  }

  /* 
  Open or create a DB for the passed realm
  */
  openTheDB(String realm) async {
    await _initDB(realm: realm);
  }

  closeTheDB(String realm) async {
    SQLiteWrapper().closeDB(dbName: realm);
  }

  _initDB({inMemory = false, random = false, String? realm}) async {
    if (!inMemory && !random && realm == null) {
      throw ("You should set at least one property of the initDB method");
    }
    String dbPath = inMemoryDatabasePath;
    if (!inMemory) {
      if (random) {
        realm = DateTime.now().millisecondsSinceEpoch.toString();
      }
      dbPath = "$_basePath/syncDatabase_${realm!}.sqlite";
    }
    /*  final docDir = await getApplicationDocumentsDirectory();
      if (!await docDir.exists()) {
        await docDir.create(recursive: true);
      }
      dbPath = p.join(docDir.path, "syncDatabase.sqlite");
    }*/
    final DatabaseInfo dbInfo = await SQLiteWrapper()
        .openDB(dbPath, onCreate: () => onCreate(realm: realm!), dbName: realm);
    // Print where the database is stored
    print("Database path: ${dbInfo.path}");
  }

  Future<void> onCreate({required String realm}) async {
    const String sql = """
          CREATE TABLE IF NOT EXISTS sync_data (
              id integer PRIMARY KEY AUTOINCREMENT NOT NULL, 
              userid integer NOT NULL, 
              clientid varchar(36) NOT NULL,  
              tablename varchar(255) NOT NULL,  
              rowguid varchar(36) NOT NULL,  
              operation char(1) NOT NULL,  
              clientdate timestamp(128) NOT NULL,
              serverdate timestamp(128) NOT NULL
              );

          CREATE TABLE IF NOT EXISTS users (
              id integer PRIMARY KEY AUTOINCREMENT NOT NULL, 
              email varchar(255) NOT NULL,  
              password varchar(255) NOT NULL);
              
          CREATE TABLE IF NOT EXISTS user_clients (
              id integer PRIMARY KEY AUTOINCREMENT NOT NULL, 
              clientid varchar(36) NOT NULL, 
              userid integer NOT NULL, 
              clientdetails varchar(255) NOT NULL,  
              lastsync timestamp(128),
              syncing timestamp(128));
          
          CREATE TABLE IF NOT EXISTS data (
              rowguid varchar(36) PRIMARY KEY NOT NULL,  
              json text NOT NULL
          );

         -- INSERT INTO users ( email, password) values ('stefano.falda@gmail.com', 'sandman');
          """;
    await SQLiteWrapper().execute(sql, dbName: realm);
  }

  /// Return the user from the email/password passed
  Future<User?> getUser(String email, String password,
      {required String realm}) async {
    final User? user = await SQLiteWrapper().query(
        "SELECT * FROM ${User.table} WHERE email = ? AND password = ?",
        params: [email, password],
        fromMap: User.fromMap,
        singleResult: true,
        dbName: realm);
    return user;
  }

  /// Insert or Update the user data
  Future setUser(User user, {required String realm}) async {
    if (user.id == null) {
      return SQLiteWrapper().insert(user.toMap(), User.table, dbName: realm);
    } else {
      return SQLiteWrapper()
          .update(user.toMap(), User.table, keys: ["id"], dbName: realm);
    }
  }

  /// Return the userClient from the userid and clientId
  Future<UserClient?> getUserClient(String clientId,
      {required String realm}) async {
    final UserClient? userClient = await SQLiteWrapper().query(
        "SELECT * FROM ${UserClient.table} WHERE clientid = ?",
        params: [clientId],
        fromMap: UserClient.fromMap,
        singleResult: true,
        dbName: realm);
    return userClient;
  }

  /// Save the Client details
  Future setUserClient(UserClient userClient, {required String realm}) {
    if (userClient.id == null) {
      return SQLiteWrapper()
          .insert(userClient.toMap(), UserClient.table, dbName: realm);
    } else {
      return SQLiteWrapper().update(userClient.toMap(), UserClient.table,
          keys: ["id"], dbName: realm);
    }
  }

  /// Get the last syncing date from a different client of the same user
  Future<UserClient?> getUserClientSyncingByUserIdAndNotClientId(
      userid, clientid,
      {required String realm}) async {
    final UserClient? userClient = await SQLiteWrapper().query(
        "SELECT * FROM ${UserClient.table} WHERE userid = ? AND clientid <> ? ORDER BY syncing LIMIT 1",
        params: [userid, clientid],
        singleResult: true,
        fromMap: UserClient.fromMap,
        dbName: realm);
    return userClient;
  }

  /// Save Sync Data
  Future setSyncData(SyncData syncData, {required String realm}) {
    return SQLiteWrapper()
        .insert(syncData.toMap(), SyncData.table, dbName: realm);
  }

  // Get Sync Data
  /*Future<List<SyncData>> getSyncData(
      {required int userid, required clientid, required DateTime since}) async {
    return List<SyncData>.from(
      await SQLiteWrapper().query(
          "SELECT * FROM ${SyncData.table} WHERE userid = ? and clientid <> ? and clientdate > ?",
          params: [userid, clientid, since.millisecondsSinceEpoch],
          fromMap: SyncData.fromMap),
    );
  }
*/

  /// Get changes from DB (required clientid, ???)
  Future<List<SyncData>> getServerChanges(
      {required int userid, required int since, required String realm}) async {
    final String sql = """
          SELECT userid, id,  rowguid, operation, tablename,  clientdate, serverdate , clientid
            FROM sync_data WHERE ID IN (
              SELECT MAX(id)   FROM sync_data WHERE userid=? AND serverdate > ?  GROUP BY rowguid
            )
        """;
    return List<SyncData>.from(await SQLiteWrapper().query(sql,
        params: [userid, since], fromMap: SyncData.fromMap, dbName: realm));
  }

  /// Return only the json data for the passed rowguid
  Future<String> getRowDataValue(String rowguid,
      {required String realm}) async {
    return await SQLiteWrapper().query(
        "SELECT json FROM ${Data.table} WHERE rowguid = ?",
        params: [rowguid],
        singleResult: true,
        dbName: realm);
  }

  /// Return the data row for the passed rowguid
  Future<Data?> getRowData(String rowguid, {required String realm}) async {
    final Data? data = await SQLiteWrapper().query(
        "SELECT * FROM ${Data.table} WHERE rowguid = ?",
        params: [rowguid],
        fromMap: Data.fromMap,
        singleResult: true,
        dbName: realm);
    return data;
  }

  /// Set the row data content
  Future setRowData(Data data, {required String realm}) {
    return SQLiteWrapper()
        .save(data.toMap(), Data.table, keys: ["rowguid"], dbName: realm);
  }

  /// Remove all data relative to the passed userid
  Future<void> deleteUserData(int userid, {required String realm}) async {
    // DELETE ALL DATAS
    return SQLiteWrapper().execute("""
      DELETE FROM data WHERE rowguid in 
          (SELECT DISTINCT rowguid FROM  sync_data  WHERE userid=$userid);

      DELETE FROM  sync_data  WHERE userid=$userid;

      DELETE FROM user_clients WHERE userid = $userid;

      DELETE FROM users WHERE id =$userid;
      """, dbName: realm);
  }

  /// Delete just the client for the passed user
  Future<void> deleteClient(int userId, String client,
      {required String realm}) async {
    return SQLiteWrapper().execute(
        "DELETE FROM user_clients WHERE userid = ? AND clientid = ?",
        dbName: realm,
        params: [userId, client]);
  }

  /// Return data relative to the current table and the passed db
  Future<List<dynamic>> getTableData(
      {required int userid,
      required String tablename,
      required String realm,
      String? additionalFilter}) {
    final String sql = """SELECT json FROM sync_data
                    INNER JOIN data on data.rowguid = sync_data.rowguid
                    WHERE  id IN (
                    SELECT MAX(id) FROM sync_data WHERE userid=$userid AND tablename=$tablename AND operation<>'D' 
                    ${additionalFilter != null ? " AND $additionalFilter" : ""}
                    GROUP BY rowguid
                  )""";
    return SQLiteWrapper().query(sql, dbName: realm) as Future<List<dynamic>>;
  }
}
