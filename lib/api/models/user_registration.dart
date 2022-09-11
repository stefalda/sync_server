class UserRegistration {
  late String email;
  late String password;
  late String clientId;
  String? clientDescription;
  bool deleteRemoteData = false;

  static UserRegistration fromMap(Map<String, dynamic> map) {
    return UserRegistration()
      ..email = map["email"]
      ..password = map['password']
      ..clientId = map['clientId']
      ..clientDescription = map['clientDescription']
      ..deleteRemoteData = map['deleteRemoteData'];
  }
}
