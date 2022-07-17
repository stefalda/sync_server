import 'package:sync_server/shared/models/sync_data.dart';

/// Classe contenente le informazioni di sincronizzazione
class SyncDetails {
  ///   Elenco degli ID rifiutati dal server e quindi da rimuovere anche su client,
  ///   questo elenco può essere utilizzato per visualizzare interfaccia i
  ///   conflitti emersi e i dati persi
  List<String> outdatedRowsGuid = <String>[];

  /// Elenco delle modifiche da apportare al DB locale sulla base di quanto
  /// presente sul server
  List<SyncData> data = <SyncData>[];

  toJson() {
    return {
      'outdatedRowsGuid': outdatedRowsGuid,
      'data': data.map((e) => e.toMapFull()).toList()
    };
  }
}
