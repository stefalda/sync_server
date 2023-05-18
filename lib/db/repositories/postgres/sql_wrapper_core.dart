library sql_wrapper;

// ignore: depend_on_referenced_packages

import 'dart:async';

import 'package:postgres/postgres.dart';

typedef FromMap = dynamic Function(Map<String, dynamic> map);

typedef OnUpgrade = Future<void> Function(int fromVersion, int toVersion);

typedef OnCreate = Future<void> Function();

const defaultDBName = "mainDB";

const paramsNames = [
  "@a",
  "@b",
  "@c",
  "@d",
  "@e",
  "@f",
  "@g",
  "@h",
  "@i",
  "@l",
  "@m",
  "@n",
  "@o"
];

class DatabaseInfo {
  final String path;
  final bool created;
  final int version;
  final String sqliteVersion;
  final String dbName;

  DatabaseInfo(
      {required this.path,
      required this.created,
      required this.version,
      required this.sqliteVersion,
      required this.dbName});
}

class StreamInfo {
  String sql;
  List<String> tables;
  StreamController controller;
  List<Object?> params;
  FromMap? fromMap;
  bool singleResult;
  String dbName;
  StreamInfo(
      {required this.sql,
      required this.tables,
      required this.controller,
      this.params = const [],
      this.fromMap,
      required this.dbName,
      this.singleResult = false});
}

class SQLWrapperCore {
  static final List<StreamInfo> streams = [];
  bool debugMode = true;
  PostgreSQLConnection? _connection;

  /// Open the Database and returns true if the Database has been created
  Future<void> openDB() async {
    print("openDB");
    if (_connection != null) return;
    _connection = PostgreSQLConnection("localhost", 5432, "sync_server",
        username: "postgres", password: "M@tilde07");
    await _connection!.open();
    print("openDB SUCCESSFULL");

    //assert(_connection.isClosed, "Connection is still closed");
  }

  /// Close the Database
  Future<void> closeDB({String? dbName}) async {
    print("closeDB");
    await _connection!.close();
    print("closeDB SUCCESSFULL");
  }

  /// Database accessible from outside (map the internal db instance)
  PostgreSQLConnection getConnection() {
    return _connection!;
  }

  /// Executes an SQL Query with no return value
  /// params - an optional list of parameters to pass to the query
  /// tables - an optional list of tables affected by the query
  Future<dynamic>? execute(String sql,
      {List<String>? tables,
      List<Object?> params = const [],
      String? dbName}) async {
    if (debugMode) {
      // ignore: avoid_print
      print("execute: $sql - params: $params - tables: $tables");
    }
    final String sqlCommand = sql.substring(0, sql.indexOf(" ")).toUpperCase();
    final paramsMap = _getParamsMap(params);
    sql = _prepareSql(sql);
    final db = _getDB(dbName);

    if (debugMode) {
      // ignore: avoid_print
      print("sql: $sql - params: $params - tables: $tables");
    }

    switch (sqlCommand) {
      case "INSERT":
        // Return the ID of last inserted row
        dynamic result;
        if (sql.contains(' RETURNING ')) {
          PostgreSQLResult res =
              await db.query(sql, substitutionValues: paramsMap);
          if (res.length == 1 && res.columnDescriptions.length == 1) {
            result = res.first.toColumnMap().values.first;
          }
        } else {
          await db.execute(sql, substitutionValues: paramsMap);
        }
        updateStreams(tables);
        //print(result);
        if (result is int) return result;
        return -1;
      case "UPDATE":
        // Return number of changes made
        final int updated =
            await db.execute(sql, substitutionValues: paramsMap);
        updateStreams(tables);
        return updated;
      case "DELETE":
        // Return number of changes made
        final int deleted =
            await db.execute(sql, substitutionValues: paramsMap);
        updateStreams(tables);
        return deleted;
      default:
        return await db.execute(sql, substitutionValues: paramsMap);
    }
  }

  String _prepareSql(String sql) {
    int idx = 0;
    while (sql.contains("?")) {
      sql = sql.replaceFirst("?", paramsNames[idx]);
      idx++;
    }
    return sql;
  }

  Map<String, dynamic> _getParamsMap(List<Object?> params) {
    final Map<String, dynamic> map = {};
    for (int i = 0; i < params.length; i++) {
      map[paramsNames[i].substring(1)] = params[i];
    }
    return map;
  }

  /// Executes an SQL Query that return a single value
  /// params - an optional list of parameters to pass to the query
  /// fromMap - a function that convert the result map to the returned object
  /// singleResult - return an object instead of a list of objects
  Future<dynamic> query(String sql,
      {List<Object?> params = const [],
      FromMap? fromMap,
      bool singleResult = false,
      String? dbName}) async {
    sql = _prepareSql(sql);
    final paramsMap = _getParamsMap(params);
    final PostgreSQLResult results =
        await _getDB(dbName).query(sql, substitutionValues: paramsMap);
    if (singleResult) {
      if (results.isEmpty) {
        return null;
      }
      // Single results
      final Map<String, dynamic> result = results.first.toColumnMap();
      // If only a column has been extracted return the simple object
      if (result.keys.length == 1) {
        return result[result.keys.first];
      }
      if (fromMap != null) {
        // The fromMap method converts the Map to the returned object
        try {
          final map = result;
          //  _rowToMap(result);
          return fromMap(map);
        } catch (error) {
          // ignore: avoid_print
          print(error.toString());
        }
      }
      return result;
    }
    // Multiple results
    // Return just a simple field object
    if (results.isNotEmpty && results.first.toColumnMap().keys.length == 1) {
      final String onlyField = results.first.toColumnMap().keys.first;
      return results.map((e) => e.toColumnMap()[onlyField]).toList();
    }
    if (fromMap != null) {
      return results.map((map) => fromMap(map.toColumnMap())).toList();
    }
    // Return a list of Map
    return results.map((e) => e.toColumnMap()).toList();
  }

  Future<int> update(Map<String, dynamic> map, String table,
      {required List<String> keys, String? dbName}) async {
    //VALUES
    String updateClause = "";
    final List params = [];
    final values = map.keys.where((element) => !keys.contains(element));
    for (String value in values) {
      if (updateClause.isNotEmpty) updateClause += ", ";
      updateClause += "$value=?";
      params.add(map[value]);
    }
    // KEYS
    String whereClause = "";
    for (String key in keys) {
      if (whereClause.isNotEmpty) whereClause += ", ";
      whereClause += "$key=?";
      params.add(map[key]);
    }

    final String sql = "UPDATE $table SET $updateClause WHERE $whereClause";
    final res =
        await execute(sql, tables: [table], params: params, dbName: dbName);
    return res;
  }

  /// Insert a new record in the passed table based on the map object
  /// and return the new id
  Future<int> insert(Map<String, dynamic> map, String table,
      {required List<String> keys, String? dbName}) async {
    return _insertOrUpdate(map, table, dbName: dbName, keys: keys);
  }

  // Perform an INSERT or an UPDATE depending on the record state (UPSERT)
  Future<int> save(Map<String, dynamic> map, String table,
      {required List<String> keys, String? dbName}) async {
    return _insertOrUpdate(map, table, keys: keys, dbName: dbName);
  }

  /// Method called internally to perform an insert or to perform an UPSERT
  /// if a keys list is provided
  /// (if a value is already present is performed an update instead of an insert)
  Future<int> _insertOrUpdate(Map<String, dynamic> map, String table,
      {required List<String> keys, String? dbName}) async {
    //VALUES
    String insertClause = "";
    String insertValues = "";
    List params = [];

    for (String value in map.keys) {
      if (insertClause.isNotEmpty) {
        insertClause += ", ";
        insertValues += ", ";
      }
      // Don't add null keys
      if (map[value] != null) {
        insertClause += value;
        insertValues += "?";
        params.add(map[value]);
      }
    }
    String sql = "INSERT INTO $table ($insertClause) VALUES ($insertValues) ";
    if (keys.length == 1) {
      sql += " RETURNING ${keys[0]}";
    }
    // CREATE AN UPSERT
    try {
      return await execute(sql,
          tables: [table], params: params, dbName: dbName);
    } catch (ex) {
      // Intercept the key already exists error...
      if (ex is PostgreSQLException && ex.code == "23505") {
        return await update(map, table, keys: keys);
      } else {
        print(ex.toString());
        // Some other error...
        return -1;
      }
    }
  }

  /// DELETE the item building the SQL query using the table and the id passed
  Future<int> delete(Map<String, dynamic> map, String table,
      {required List<String> keys, String? dbName}) async {
    final List params = [];
    // KEYS
    String whereClause = "";
    for (String key in keys) {
      if (whereClause.isNotEmpty) whereClause += ", ";
      whereClause += "$key=?";
      params.add(map[key]);
    }

    final String sql = "DELETE FROM $table WHERE $whereClause";
    final res =
        await execute(sql, tables: [table], params: params, dbName: dbName);
    return res;
  }

  /// Executes an SQL Query that return a single value
  /// params - an optional list of parameters to pass to the query
  /// fromMap - a function that convert the result map to the returned object
  /// singleResult - return an object instead of a list of objects
  Stream watch(String sql,
      {List<Object?> params = const [],
      FromMap? fromMap,
      bool singleResult = false,
      required List<String> tables,
      String? dbName}) {
    final StreamController sc = StreamController();
    // Initial values
    final StreamInfo streamInfo = StreamInfo(
        controller: sc,
        sql: sql,
        tables: tables,
        params: params,
        fromMap: fromMap,
        dbName: dbName ?? defaultDBName,
        singleResult: singleResult);
    streams.add(streamInfo);
    _updateStream(streamInfo);
    // Remove from list of streams
    sc.done.then((value) => streams.remove(streamInfo));
    return sc.stream;
  }

  /// Reload data in stream emitting the new result
  Future<void> _updateStream(StreamInfo streamInfo) async {
    dynamic results = await query(streamInfo.sql,
        params: streamInfo.params,
        singleResult: streamInfo.singleResult,
        fromMap: streamInfo.fromMap,
        dbName: streamInfo.dbName);
    streamInfo.controller.add(results);
  }

  /// Update all the streams connected to one of the table in the list
  Future<void> updateStreams(List<String>? tables) async {
    if (tables == null || tables.isEmpty) return;
    for (StreamInfo s in streams) {
      for (String table in tables) {
        if (s.tables.contains(table)) {
          await _updateStream(s);
          continue;
        }
      }
    }
  }

  // Return the database instance with the passed name
  PostgreSQLConnection _getDB(String? dbName) {
    // assert(_connection.isClosed,
    //     "It seems the openDB method has not been called!");
    return _connection!;
  }
}
