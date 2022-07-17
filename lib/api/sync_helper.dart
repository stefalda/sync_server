import 'dart:convert';

import 'package:sync_server/api/models/sync_details.dart';
import 'package:sync_server/api/models/sync_info.dart';
import 'package:sync_server/db/database_repository.dart';
import 'package:sync_server/db/models/data.dart';
import 'package:sync_server/db/models/user_client.dart';
import 'package:sync_server/shared/models/sync_data.dart';

class SyncHelper {
  /// Method called from the PULL Endpoint
  static Future<SyncDetails> pull(
      {required String clientid,
      required int lastSync,
      required List<SyncData> clientChanges,
      required String realm}) async {
    final SyncDetails syncDetails = SyncDetails();
    await DatabaseRepository().openTheDB(realm);
    try {
      // Ottieni il client
      final UserClient? userClient =
          await DatabaseRepository().getUserClient(clientid, realm: realm);
      if (userClient == null) {
        throw Exception("Client id not found!");
      }

      // Verifica che non ci sia un'altra sincronizzazione in corso per l'utente
      if (await isAlreadySyncing(userClient.userid, clientid, realm: realm)) {
        throw Exception("The user is already syncing elsewhere");
      }
      // Segna la sincronizzazione come attiva
      userClient.syncing = DateTime.now().toUtc();
      DatabaseRepository().setUserClient(userClient, realm: realm);

      // Ottieni la data

      // Cicla sui cambiamenti presenti sul server
      final List<SyncData> serverChanges = await DatabaseRepository()
          .getServerChanges(
              userid: userClient.userid,
              since: userClient.lastsync.millisecondsSinceEpoch,
              realm: realm);

      // Confronta i cambiamenti presenti sul client con quelli del server
      // per capire se alcuni sono sorpassati e non vanno acquisiti (e viceversa)
      for (SyncData client in clientChanges) {
        // Filter server data by rowguid and check the date
        final serverData =
            serverChanges.where((server) => server.rowguid == client.rowguid);
        if (serverData.isNotEmpty) {
          // Only the latest value is returned for the specific id
          final server = serverData.first;
          // Se il dato del server è più recente di quello sul client scarta la modifica proveniente dal client
          if (server.clientdate.millisecondsSinceEpoch >=
              client.clientdate.millisecondsSinceEpoch) {
            syncDetails.outdatedRowsGuid.add(client.rowguid.toString());
          } else {
            // Rimuovi dai cambiamenti del server quello presente dal momento che andrà sovrascritto con
            // quello del client (quindi non ha senso inviarlo al client)
            serverChanges.remove(server);
          }
        }
      }
      // Aggiungi ai serverChanges i dati da inviare al client per il suo aggiornamento
      // a meno che si tratti di una cancellazione
      for (SyncData serverChange in serverChanges) {
        if (serverChange.operation != "D") {
          serverChange.rowData = jsonDecode(await DatabaseRepository()
              .getRowDataValue(serverChange.rowguid, realm: realm));
        }
      }
      // Aggiungi a syncDetails le modifiche presenti sul server e da applicare sul client
      syncDetails.data.addAll(serverChanges);
      return syncDetails;
    } finally {
      DatabaseRepository().closeTheDB(realm);
    }
  }

  /// Verifica se è in corso una sincronizzazione per lo stesso utente da un altro client
  /// Se la sincronizzazione è troppo vecchia la rimuove...
  static Future<bool> isAlreadySyncing(int userid, String clientid,
      {required String realm}) async {
    final UserClient? userClient = await DatabaseRepository()
        .getUserClientSyncingByUserIdAndNotClientId(userid, clientid,
            realm: realm);
    if (userClient == null || userClient.syncing == null) return false;
    // Verifica se la sincronizzazione dura da più di 5', nel caso annullala
    if (DateTime.now().difference(userClient.syncing!).inMinutes > 5) {
      userClient.syncing = null;
      DatabaseRepository().setUserClient(userClient, realm: realm);
      return false;
    }
    return true;
  }

  static Future<SyncInfo> push(
      {required String clientid,
      required int lastSync,
      required List<SyncData> clientChanges,
      required String realm}) async {
    await DatabaseRepository().openTheDB(realm);
    try {
      // Ottieni il client
      final UserClient? userClient =
          await DatabaseRepository().getUserClient(clientid, realm: realm);
      if (userClient == null) {
        throw Exception("Client id not found!");
      }

      // Verifica che non ci sia un'altra sincronizzazione in corso per l'utente
      if (userClient.syncing == null) {
        throw Exception("You should pull before pushing...");
      }

      for (SyncData clientChange in clientChanges) {
        // Aggiorna i dati a partire da quanto contenuto nel campo data
        //print(
        //    "Table:${clientChange.tablename} Operation:${clientChange.operation} Key:${clientChange.rowguid}");
        processData(clientChange, userClient.userid, realm: realm);
        // Inserisci la riga sulla tabella SyncData del server aggiungendo la data
        //it.rowguid = UUID.fromString(it.rowguid)
        clientChange.serverdate = DateTime.now().toUtc();
        clientChange.userid = userClient.userid;
        clientChange.clientid = clientid;
        await DatabaseRepository().setSyncData(clientChange, realm: realm);
      }
      // Aggiorna la data di ultima sincronizzazione per il client
      userClient.lastsync = DateTime.now().toUtc();
      userClient.syncing = null;
      await DatabaseRepository().setUserClient(userClient, realm: realm);
      return SyncInfo(DateTime.now());
    } finally {
      DatabaseRepository().closeTheDB(realm);
    }
  }

  /// Provvedi alle operazioni di inserimento, aggiornamento e cancellazione sulla tabella indicata
  static processData(SyncData syncData, int userid,
      {required String realm}) async {
    Data? data =
        await DatabaseRepository().getRowData(syncData.rowguid, realm: realm);
    if (data == null) {
      data = Data()
        ..rowguid = syncData.rowguid
        ..json = syncData.rowDataAsJson!;
    } else {
      if (syncData.operation != "D") {
        data.json = syncData.rowDataAsJson!;
      }
    }
    await DatabaseRepository().setRowData(data, realm: realm);
  }
}
