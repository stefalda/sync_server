class Data {
  static const String table = "data";
  //int? id;
  late String rowguid;
  late String json;

  static Data fromMap(Map<String, dynamic> map) {
    return Data()
      //  ..id = map['id']
      ..rowguid = map["rowguid"]
      ..json = map["json"];
  }

//'id': id,
  Map<String, dynamic> toMap() {
    return {'rowguid': rowguid, 'json': json};
  }
}
