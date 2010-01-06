ChatWebSocketHandler := WebSocketHandler clone do(
  authenticate := method(sessionId,
    super(authenticate(sessionId)) ifTrue(
      log debug("Authenticated user session #{sessionId}")
      self chatController := ChatController clone setSession(self session)
      self socket send({authDetails: true, user: self session user} asJson)))

  processMessage := method(msg,
    self chatController post(msg["body"]))
)