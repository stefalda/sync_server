class User {
  static const String table = "users";

  int? id;
  String? name;
  String? email;
  String? password;
  String? salt;

  static User fromMap(Map<String, dynamic> map) {
    return User()
      ..name = map["name"]
      ..email = map["email"]
      ..password = map["password"]
      ..salt = map["salt"]
      ..id = map["id"];
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'salt': salt
    };
  }
}
