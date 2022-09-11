import 'package:sync_server/api/models/user_registration.dart';
import 'package:sync_server/db/models/user.dart';
import 'package:sync_server/db/models/user_client.dart';

import '../db/database_repository.dart';

class UserHelper {
  static final UserHelper _singleton = UserHelper._internal();
  factory UserHelper() {
    return _singleton;
  }

  UserHelper._internal();

  /// Register a new user and client (or just client if the user already exists)
  Future<void> register(UserRegistration userRegistration,
      {required String realm}) async {
    await DatabaseRepository().openTheDB(realm);
    try {
      //Verifica se lo username è corretto
      User? user = await DatabaseRepository().getUser(
          userRegistration.email, userRegistration.password,
          realm: realm);

      if (user == null) {
        user = User()
          ..email = userRegistration.email
          ..password = userRegistration.password;
        user.id = await DatabaseRepository().setUser(user, realm: realm);
      }
      // Adesso inserisci la riga sulla tabella degli UserClient
      UserClient? userClientOpt = await DatabaseRepository()
          .getUserClient(userRegistration.clientId, realm: realm);
      if (userClientOpt != null) {
        if (userClientOpt.userid != user.id) {
          throw ("Client id already registered to another user");
        } else {
          // Il client è già correttamente associato all'utente
          return;
        }
      } else {
        // Nuova registrazione
        final userClient = UserClient()
          ..userid = user.id!
          ..clientid = userRegistration.clientId
          ..clientdetails = userRegistration.clientDescription;
        await DatabaseRepository().setUserClient(userClient, realm: realm);
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
