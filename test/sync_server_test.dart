import 'dart:convert';
import 'dart:io';

import 'package:sqlite_wrapper/sqlite_wrapper.dart';
import 'package:sync_server/api/models/sync_details.dart';
import 'package:sync_server/api/models/sync_info.dart';
import 'package:sync_server/api/models/user_registration.dart';
import 'package:sync_server/api/sync_helper.dart';
import 'package:sync_server/api/users_helper.dart';
import 'package:sync_server/db/models/data.dart';
import 'package:sync_server/db/models/user_client.dart';
import 'package:sync_server/db/repositories/repositories.dart';
import 'package:sync_server/db/repositories/sqlite/database_repository.dart';
import 'package:sync_server/shared/models/sync_data.dart';
import 'package:test/test.dart';

import 'database_repository_test.dart';
import 'mock_data.dart';

void main() {
  setUpAll(() async {
    // Remove the db if already existing
    const dbName = 'syncDatabase_$realm.sqlite';
    final f = File(dbName);
    if (f.existsSync()) {
      f.deleteSync();
    }
    SQLiteWrapper().openDB(dbName,
        onCreate: () => DatabaseRepository().onCreate(realm: realm),
        dbName: realm);
  });

  group("Register user and its clients", () {
    test('register a new user', () async {
      UserRegistration ur = UserRegistration()
        ..email = "test@test.com"
        ..clientId = "CLIENT1"
        ..password = "test"
        ..clientDescription = "FIRST VIRTUAL DEVICE";
      UserHelper().register(ur, realm: realm);
    });

    test("get the registered client info", () async {
      // Get the client device
      UserClient? userClient =
          await getDatabaseRepository().getUserClient("CLIENT1", realm: realm);
      expect(userClient, isNotNull);
      expect(userClient?.userid, 1);
    });

    test('register again the same user and client', () async {
      UserRegistration ur = UserRegistration()
        ..email = "test@test.com"
        ..clientId = "CLIENT1"
        ..password = "test"
        ..clientDescription = "FIRST VIRTUAL DEVICE";
      await UserHelper().register(ur, realm: realm);
      // Expect that there's still just one client for current user
      final int count = await SQLiteWrapper().query(
          "SELECT COUNT(*) FROM ${UserClient.table} WHERE userid = ?",
          params: [1],
          dbName: realm,
          singleResult: true);
      expect(count, 1);
    });

    test('register the same user for a second client', () async {
      UserRegistration ur = UserRegistration()
        ..email = "test@test.com"
        ..clientId = "CLIENT2"
        ..password = "test"
        ..clientDescription = "SECOND VIRTUAL DEVICE";
      await UserHelper().register(ur, realm: realm);
      final int count = await SQLiteWrapper().query(
          "SELECT COUNT(*) FROM ${UserClient.table} WHERE userid = ?",
          params: [1],
          singleResult: true,
          dbName: realm);
      expect(count, 2);
    });
  });

  group("Perform a pull and push", () {
    // Insert some data
    setUpAll(() async => await setServerChanges());
    SyncDetails? syncDetails;
    test('try to push before pulling expeting an exception', () {
      expect(
          () async => SyncHelper.push(
              clientid: "CLIENT1",
              lastSync: 0,
              clientChanges: [],
              realm: realm),
          throwsA(predicate((Exception e) =>
              e.toString().contains("You should pull before pushing..."))));
    });

    test('try to pull AND pull from client2', () async {
      syncDetails = await SyncHelper.pull(
          clientid: "CLIENT2",
          lastSync: 0,
          clientChanges: getClientChanges(),
          realm: realm);
      // Data should be the list of server data not conflicting with client
      expect(syncDetails!.data.length, 4);
      // Conflicting ids that should be replaced in the client
      expect(syncDetails!.outdatedRowsGuid.length, 1);
    });

    test('try to push from client2', () async {
      await getDatabaseRepository().openTheDB(realm);
      List<SyncData> changes = getClientChanges();
      changes = changes
          .where((value) =>
              (!syncDetails!.outdatedRowsGuid.contains(value.rowguid)))
          .toList();
      expect(changes.length, 4);
      final SyncInfo syncInfo = await SyncHelper.push(
          clientid: "CLIENT2",
          lastSync: 0,
          clientChanges: changes,
          realm: realm);
      // Data should be the list of server data not conflicting with client
      expect(syncInfo.lastSync, isNotNull);
      await getDatabaseRepository().openTheDB(realm);
      final int count = await SQLiteWrapper().query(
          "SELECT COUNT(*) FROM ${Data.table}",
          singleResult: true,
          dbName: realm);
      expect(count, 8);
      Data? data =
          await getDatabaseRepository().getRowData("teta", realm: realm);
      expect(data, isNotNull);
      expect(jsonDecode(data!.json)["fairytale"], "Cenerentola");
    });
  });
}
