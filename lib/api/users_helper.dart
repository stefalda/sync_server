import 'package:sync_server/api/models/user_registration.dart';
import 'package:sync_server/db/models/user.dart';
import 'package:sync_server/db/models/user_client.dart';

import '../db/database_repository.dart';

class WrongPasswordException implements Exception {}

class EmailConflictException implements Exception {}

/*
enum ErrorCode { wrongPassword, emailAlreadyRegistered }

class CustomException implements Exception {
  final String cause;
  final ErrorCode errorCode;
  CustomException(this.cause, this.errorCode);
  @override
  String toString() {
    return "$cause | ${errorCode.name}";
  }
}
*/

class UserHelper {
  static final UserHelper _singleton = UserHelper._internal();
  factory UserHelper() {
    return _singleton;
  }

  UserHelper._internal();

  /// Register a new user and client (or just client if the user already exists)
  Future<UserRegistration> register(UserRegistration userRegistration,
      {required String realm}) async {
    await DatabaseRepository().openTheDB(realm);
    try {
      //Verifica se lo username è corretto
      User? user = await DatabaseRepository().getUser(
          userRegistration.email, userRegistration.password,
          realm: realm);
      if (user == null) {
        // L'utente con quella password non è stato trovato...
        if (!userRegistration.newRegistration) {
          throw WrongPasswordException();
        }
        // New registration
        user = User()
          ..name = userRegistration.name
          ..email = userRegistration.email
          ..password = userRegistration.password;
        user.id = await DatabaseRepository().setUser(user, realm: realm);
      } else {
        // User exists
        if (userRegistration.newRegistration) {
          throw EmailConflictException();
        }
        // Assign the name
        userRegistration.name = user.name;
      }
      // Adesso inserisci la riga sulla tabella degli UserClient
      UserClient? userClientOpt = await DatabaseRepository()
          .getUserClient(userRegistration.clientId, realm: realm);
      if (userClientOpt != null) {
        if (userClientOpt.userid != user.id) {
          throw ("Client id already registered to another user");
        } else {
          // Il client è già correttamente associato all'utente
          return userRegistration;
        }
      } else {
        // Nuova registrazione
        final userClient = UserClient()
          ..userid = user.id!
          ..clientid = userRegistration.clientId
          ..clientdetails = userRegistration.clientDescription;
        await DatabaseRepository().setUserClient(userClient, realm: realm);
        return userRegistration;
      }
    } finally {
      await DatabaseRepository().closeTheDB(realm);
    }
  }

  /// Delete all sync data associated to the user
  unregister(UserRegistration userRegistration, {required String realm}) async {
    //Verifica se lo username è corretto
    await DatabaseRepository().openTheDB(realm);
    try {
      User? user = await DatabaseRepository().getUser(
          userRegistration.email, userRegistration.password,
          realm: realm);
      if (user == null) {
        throw ("Username or password missing");
      }
      if (userRegistration.deleteRemoteData) {
        // Delete from all tables
        await DatabaseRepository().deleteUserData(user.id!, realm: realm);
      } else {
        // Delete only the client
        await DatabaseRepository()
            .deleteClient(user.id!, userRegistration.clientId, realm: realm);
      }
    } finally {
      await DatabaseRepository().closeTheDB(realm);
    }
  }
}
