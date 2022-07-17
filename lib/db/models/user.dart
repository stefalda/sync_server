class User {
  static const String table = "users";

  int? id;
  String? email;
  String? password;

  static User fromMap(Map<String, dynamic> map) {
    return User()
      ..email = map["email"]
      ..password = map["password"]
      ..id = map["id"];
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'email': email, 'password': password};
  }
}
