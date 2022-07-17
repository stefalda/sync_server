class UserClient {
  static const String table = "user_clients";
  int? id;
  late String clientid;
  late int userid;
  String? clientdetails;
  DateTime lastsync = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? syncing;

  static UserClient fromMap(Map<String, dynamic> map) {
    return UserClient()
      ..id = map["id"]
      ..clientid = map["clientid"]
      ..userid = map["userid"]
      ..clientdetails = map["clientdetails"]
      ..lastsync = map["lastsync"] != null
          ? (DateTime.fromMillisecondsSinceEpoch(map["lastsync"]))
          : DateTime.fromMillisecondsSinceEpoch(0)
      ..syncing = map["syncing"] != null
          ? (DateTime.fromMillisecondsSinceEpoch(map["syncing"]))
          : null;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientid': clientid,
      'userid': userid,
      'clientdetails': clientdetails,
      'lastsync': lastsync.millisecondsSinceEpoch,
      'syncing': syncing?.millisecondsSinceEpoch
    };
  }
}
