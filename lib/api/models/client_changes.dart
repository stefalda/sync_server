import 'package:sync_server/shared/models/sync_data.dart';

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
