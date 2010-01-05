ChatController := Controller clone do(
  beforeFilter("dontCache")
  beforeFilter("requireAuth", {except: ["index", "login", "register", "updates"]})
 
  index := method(
    if(isLoggedIn, File with("static/chat/room.html"), redirectToRoute("login")))
  
  register := method(nick, password, email,
    isGET ifTrue(return File with("static/chat/register.html"))

    user := Person create({_id: email, email: email, nick: nick, password: password, logins:[]})
    
    login(email, password))

  login := method(email, password,
    isGET ifTrue(return File with("static/chat/login.html"))
    
    user := Person auth(email, password)
    if(user not, Exception raise("authFailure"))
    
    session user := user
    #Channel subscribers append(self createFutureResponse("channel"))
    redirectTo("/chat"))

  logout := method(
    Channel streamFor(self streamId) ?close
    destroySession

    redirectToRoute("root"))
  
  post := method(body,
    msg := ChatMessage create({created_at: Date now, body: body, user_id: session user id})
    msg atPut("user_nick", self session user["nick"])
    Channel send(msg asJson, [self streamId])
    msg)

  updates := method(
    Channel streamFor(self streamId) returnIfNonNil
    
    if(self isWebSocket,
      self webSocket := client := self createWebSocket(self streamId, ChatWebSocketHandler clone),
      client := self createFutureResponse(self streamId))

    Channel subscribe(client))

### Private slots ###
  streamId := method("chat-stream-for-" .. (self session sessionId))
  isLoggedIn := method(session ?user isNil not)

  requireAuth := method(
    isLoggedIn ifFalse(Exception raise("authRequired")))
)
