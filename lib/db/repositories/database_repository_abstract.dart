import 'package:crypt/crypt.dart';
import 'package:sync_server/db/models/data.dart';
import 'package:sync_server/db/models/user.dart';
import 'package:sync_server/db/models/user_client.dart';
import 'package:sync_server/shared/models/sync_data.dart';

abstract class DatabaseRepositoryAbstract {
  /* 
  Open or create a DB for the passed realm
  */
  Future<void> openTheDB(String realm);

  Future<void> closeTheDB(String realm);

  /// Return the user from the email/password passed
  Future<User?> getUser(String email, String password, {required String realm});

  /// Insert or Update the user data
  Future setUser(User user, {required String realm});

  /// Return the userClient from the userid and clientId
  Future<UserClient?> getUserClient(String clientId, {required String realm});

  /// Save the Client details
  Future setUserClient(UserClient userClient, {required String realm});

  /// Get the last syncing date from a different client of the same user
  Future<UserClient?> getUserClientSyncingByUserIdAndNotClientId(
      userid, clientid,
      {required String realm});

  /// Save Sync Data
  Future setSyncData(SyncData syncData, {required String realm});

  /// Get changes from DB (required clientid, ???)
  Future<List<SyncData>> getServerChanges(
      {required int userid, required int since, required String realm});

  /// Return only the json data for the passed rowguid
  Future<String> getRowDataValue(String rowguid, {required String realm});

  /// Return the data row for the passed rowguid
  Future<Data?> getRowData(String rowguid, {required String realm});

  /// Set the row data content
  Future setRowData(Data data, {required String realm});

  /// Remove all data relative to the passed userid
  Future<void> deleteUserData(int userid, {required String realm});

  /// Delete just the client for the passed user
  Future<void> deleteClient(int userId, String client, {required String realm});

  /// Return data relative to the current table and the passed db
  Future<List<dynamic>> getTableData(
      {required int userid,
      required String tablename,
      required String realm,
      String? additionalFilter});

  String encryptPassword(String password, String salt) {
    return Crypt.sha512(password, salt: salt).toString();
  }
}
