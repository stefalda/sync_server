handleWebSocket(app) {
  /// TODO --- Web socket implementation
/*
  // Track connected clients
  var wsSessions = <WebSocketSession>[];

// Web socket route
  app.get(
    '/ws',
    () => WebSocketSession(
      onOpen: (ws) {
        // Join chat
        wsSessions.add(ws);
        wsSessions
            .where((user) => user != ws)
            .forEach((user) => user.send('A new user joined the chat.'));
      },
      onClose: (ws) {
        // Leave chat
        wsSessions.remove(ws);
        for (var user in wsSessions) {
          user.send('A user has left.');
        }
      },
      onMessage: (ws, dynamic data) {
        // Deliver messages to all users
        for (var user in wsSessions) {
          user.send(data);
        }
      },
    ),
  );
  */
}
