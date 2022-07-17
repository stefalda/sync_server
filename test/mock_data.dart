import 'package:sync_server/db/database_repository.dart';
import 'package:sync_server/db/models/data.dart';
import 'package:sync_server/shared/models/sync_data.dart';

import 'database_repository_test.dart';

/// Ipotizza di popolare una tabella di personaggi delle fiabe
/// Partiamo dai 7 nani
/// Il server ne ha 3 caricati dal client 1
/// Il client 2 ne ha 4 non ancora caricati
//
Future<void> setServerChanges() async {
  List<Map<String, dynamic>> datas = [
    {
      "userid": 1,
      "clientid": "CLIENT1",
      "tablename": "characters",
      "rowguid": "teta",
      "operation": "I",
      "clientdate": 0,
      "serverdate": 1
    },
    {
      "userid": 1,
      "clientid": "CLIENT1",
      "tablename": "characters",
      "rowguid": "alfa",
      "operation": "I",
      "clientdate": 1653753710136,
      "serverdate": 1653753710200,
    },
    {
      "userid": 1,
      "clientid": "CLIENT1",
      "tablename": "characters",
      "rowguid": "beta",
      "operation": "I",
      "clientdate": 1653753710136,
      "serverdate": 1653753710200
    },
    {
      "userid": 1,
      "clientid": "CLIENT1",
      "tablename": "characters",
      "rowguid": "gamma",
      "operation": "I",
      "clientdate": 1653753710136,
      "serverdate": 1653753710200
    },
    {
      "userid": 1,
      "clientid": "CLIENT1",
      "tablename": "characters",
      "rowguid": "teta",
      "operation": "U",
      "clientdate": 1653753710301,
      "serverdate": 1653753711300
    }
  ];
  List<Map<String, dynamic>> characters = [
    {
      "rowguid": "teta",
      "json": """{
              "name": "Cenerentola",
              "fairytale": "Pollicino"
        }"""
    },
    {
      "rowguid": "alfa",
      "json": """{
              "name": "Pisolo",
              "fairytale": "Biancaneve"
        }"""
    },
    {
      "rowguid": "beta",
      "json": """{
              "name": "Brontolo",
              "fairytale": "Biancaneve"
        }"""
    },
    {
      "rowguid": "gamma",
      "json": """{
              "name": "Eolo",
              "fairytale": "Biancaneve"
        }"""
    },
    {
      "rowguid": "teta",
      "json": """{
              "name": "Cenerentola",
              "fairytale": "Cenerentola"
        }"""
    }
  ];
  for (int idx = 0; idx < datas.length; idx++) {
    await DatabaseRepository()
        .setSyncData(SyncData.fromMap(datas[idx]), realm: realm);
    await DatabaseRepository()
        .setRowData(Data.fromMap(characters[idx]), realm: realm);
  }
}

List<SyncData> getClientChanges() {
  List<Map<String, dynamic>> datas = [
    {
      "clientid": "CLIENT2",
      "tablename": "characters",
      "rowguid": "delta",
      "operation": "I",
      "clientdate": 1653753710201,
      "rowData": """{
              "name": "Mammolo",
              "fairytale": "Biancaneve"
        }"""
    },
    {
      "clientid": "CLIENT2",
      "tablename": "characters",
      "rowguid": "epsilon",
      "operation": "I",
      "clientdate": 1653753710201,
      "rowData": """{
              "name": "Cucciolo",
              "fairytale": "Biancaneve"
        }"""
    },
    {
      "clientid": "CLIENT2",
      "tablename": "characters",
      "rowguid": "zeta",
      "operation": "I",
      "clientdate": 1653753710201,
      "rowData": """{
              "name": "Dotto",
              "fairytale": "Biancaneve"
        }"""
    },
    {
      "clientid": "CLIENT2",
      "tablename": "characters",
      "rowguid": "eta",
      "operation": "I",
      "clientdate": 1653753710201,
      "rowData": """{
              "name": "Gongolo",
              "fairytale": "Biancaneve"
        }"""
    },
    {
      "clientid": "CLIENT2",
      "tablename": "characters",
      "rowguid": "teta",
      "operation": "U",
      "clientdate": 1653753710101,
      "rowData": """{
              "name": "Cenerentola",
              "fairytale": "Aladino"
        }"""
    }
  ];

  return datas.map((e) => SyncData.fromMap(e)).toList();
}
