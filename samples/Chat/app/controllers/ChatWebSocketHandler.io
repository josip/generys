ChatWebSocketHandler := WebSocketHandler clone do(
  authenticate := method(sessionId,
    super(authenticate(sessionId)) ifTrue(
      self chatController := ChatController clone setSession(self session)
      self socket send({user_data: self session user} asJson)))

  processMessage := method(msg,
    self chatController post(msg["body"]))
)