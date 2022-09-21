class UserToken {
  static const String table = "user_tokens";
  late String clientId;
  late String token;
  late String refreshToken;
  late DateTime lastRefresh; // = DateTime.fromMillisecondsSinceEpoch(0);

  get isExpired {
    return DateTime.now().difference(lastRefresh).inHours > 2;
  }

  static UserToken fromMap(Map<String, dynamic> map) {
    return UserToken()
      ..clientId = map["clientid"]
      ..token = map["token"]
      ..refreshToken = map["refreshtoken"]
      ..lastRefresh = map["lastrefresh"] != null
          ? (DateTime.fromMillisecondsSinceEpoch(map["lastrefresh"]))
          : DateTime.fromMillisecondsSinceEpoch(0);
  }

  Map<String, dynamic> toMap() {
    return {
      'clientid': clientId,
      'token': token,
      'refreshtoken': refreshToken,
      'lastrefresh': lastRefresh.millisecondsSinceEpoch
    };
  }
}
