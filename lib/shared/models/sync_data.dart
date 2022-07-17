import 'dart:convert';

class SyncData {
  static const String table = "sync_data";
  int? id;
  int? userid;
  String? clientid;
  late String tablename;
  late String rowguid;
  late String operation;
  late DateTime clientdate;
  DateTime? serverdate;
  String? rowDataAsJson;
  // Used to return data to the client
  Map<String, dynamic>? rowData;

  static SyncData fromMap(Map<String, dynamic> map) {
    // print(map);
    return SyncData()
      ..id = map["id"]
      ..userid = map["userid"]
      ..clientid = map["clientid"]
      ..tablename = map["tablename"]
      ..rowguid = map["rowguid"]
      ..operation = map["operation"]
      ..clientdate = DateTime.fromMillisecondsSinceEpoch(map["clientdate"])
      ..serverdate = map["serverdate"] != null
          ? DateTime.fromMillisecondsSinceEpoch(map["serverdate"])
          : null
      ..rowDataAsJson =
          map["rowData"] != null ? jsonEncode(map["rowData"]) : null;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userid': userid,
      'clientid': clientid,
      'tablename': tablename,
      'rowguid': rowguid,
      'operation': operation,
      'clientdate': clientdate.millisecondsSinceEpoch,
      'serverdate': serverdate?.millisecondsSinceEpoch
    };
  }

  // RowData is included only in this method because it's a temporary field
  Map<String, dynamic> toMapFull() {
    final map = toMap();
    map['rowData'] = rowData;
    return map;
  }
}
