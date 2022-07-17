class SyncInfo {
  final DateTime lastSync;

  SyncInfo(this.lastSync);

  toJson() {
    return {'lastSync': lastSync.millisecondsSinceEpoch};
  }
}
