import 'package:sync_server/shared/models/sync_data.dart';

/// JSON Format
///{
///  clientid: string,
///  lastSync: number,
///  changes: []<{
///               id: number,
///               clientId: String,
///               tablename: String,
///               rowguid: String,
///               operation: String,
///               clientdate: Date,
///               serverdate: Date,
///               rowDataAsJson: String
///               }
/// }
///

class ClientChanges {
  late String clientId;
  late int lastSync;
  late List<SyncData> changes;

  static ClientChanges fromMap(Map jsonData) {
    return ClientChanges()
      ..clientId = jsonData['clientId']
      ..lastSync = jsonData['lastSync']
      ..changes = List<SyncData>.from(
          jsonData['changes'].map((e) => SyncData.fromMap(e)).toList());
  }
}
