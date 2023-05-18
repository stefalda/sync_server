import 'dart:io';

import 'package:sqlite_wrapper/sqlite_wrapper.dart';
import 'package:sync_server/db/models/data.dart';
import 'package:sync_server/db/models/user.dart';
import 'package:sync_server/db/models/user_client.dart';
import 'package:sync_server/db/repositories/repositories.dart';
import 'package:sync_server/db/repositories/sqlite/database_repository.dart';
import 'package:sync_server/shared/models/sync_data.dart';
import 'package:test/test.dart';

const realm = "TEST";

//DatabaseRepository databaseRepository = DatabaseRepository();
void main() async {
  setUpAll(() async {
    // Remove the db if already existing
    const dbName = 'test_database.sqlite';
    final f = File(dbName);
    if (f.existsSync()) {
      f.deleteSync();
    }

    SQLiteWrapper().openDB(dbName,
        onCreate: () => DatabaseRepository().onCreate(realm: realm),
        dbName: realm);
  });

  test('get the user data for a missing user', () async {
    final user = await getDatabaseRepository()
        .getUser("test@test.com", "test", realm: realm);
    expect(user, isNull);
  });

  test('insert a new user', () async {
    User user = User()
      ..email = "test@test.com"
      ..password = "test";
    user.id = await getDatabaseRepository().setUser(user, realm: realm);
    expect(user.id, isNotNull);
  });

  test('get the user data for an existing user', () async {
    final user = await getDatabaseRepository()
        .getUser("test@test.com", "test", realm: realm);
    expect(user, isNotNull);
  });

  test('get a missing user client', () async {
    final userClient =
        await getDatabaseRepository().getUserClient("1234567890", realm: realm);
    expect(userClient, isNull);
  });

  test('associate a user client with a user', () async {
    final userClient = UserClient()
      ..clientid = "1234567890"
      ..userid = 1
      ..clientdetails = "TEST INSERT";
    final userClientId =
        await getDatabaseRepository().setUserClient(userClient, realm: realm);
    expect(userClientId, isNotNull);
  });

  test('get an existing user client', () async {
    final userClient =
        await getDatabaseRepository().getUserClient("1234567890", realm: realm);
    expect(userClient, isNotNull);
    expect(userClient!.id, 1);
  });

  test('update an existing user client', () async {
    final userClient =
        await getDatabaseRepository().getUserClient("1234567890", realm: realm);
    userClient!.clientdetails = "TEST MODIFIED";
    await getDatabaseRepository().setUserClient(userClient, realm: realm);

    final userClient2 =
        await getDatabaseRepository().getUserClient("1234567890", realm: realm);
    expect(userClient2!.clientdetails, "TEST MODIFIED");
  });
  test('Check if another userclient is syncing', () async {
    final UserClient? userClient = await getDatabaseRepository()
        .getUserClientSyncingByUserIdAndNotClientId(1, "1234567890",
            realm: realm);
    expect(userClient, isNull);
    // Insert another client
    final now = DateTime.now().toUtc();
    final userClient2 = UserClient()
      ..clientid = "ABCDEFGHI"
      ..userid = 1
      ..syncing = now
      ..clientdetails = "SECONDARY CLIENT";
    final newId =
        await getDatabaseRepository().setUserClient(userClient2, realm: realm);
    expect(newId, 2);
    final UserClient? userClientSyncing = await getDatabaseRepository()
        .getUserClientSyncingByUserIdAndNotClientId(1, "1234567890",
            realm: realm);
    expect(userClientSyncing, isNotNull);
    expect(userClientSyncing!.clientid, "ABCDEFGHI");
    expect(userClientSyncing.syncing!.millisecondsSinceEpoch,
        now.millisecondsSinceEpoch);
  });

  group("Simulate some sync data", () {
    test("Insert some fake data", () async {
      final SyncData syncData = SyncData()
        ..userid = 1
        ..clientid = "ABCDEFGHI"
        ..operation = "I"
        ..rowguid = "A"
        ..clientdate = DateTime.now().toUtc()
        ..tablename = "todos"
        ..serverdate = DateTime.now().toUtc();
      final id =
          await getDatabaseRepository().setSyncData(syncData, realm: realm);
      expect(id, 1);

      Data data = Data()
        ..rowguid = "A"
        ..json = "{}";
      final id2 = await getDatabaseRepository().setRowData(data, realm: realm);
      expect(id2, 1);
    });

    test("Check for modifications", () async {
      List<SyncData> changes = await getDatabaseRepository()
          .getServerChanges(userid: 1, since: 0, realm: realm);
      expect(changes.length, 1);
    });
  });

  test("Delete all user data", () async {
    await getDatabaseRepository().deleteUserData(1, realm: realm);
    // Prova a trovare l'utente
    final int count = await SQLiteWrapper().query(
        "SELECT COUNT(*) FROM ${User.table} WHERE id = ?",
        params: [1],
        dbName: realm,
        singleResult: true);
    expect(count, 0);
  });
}
