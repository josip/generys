ChatController := Controller clone do(
  beforeFilter("dontCache")
  beforeFilter("requireAuth", {except: ["index", "login", "register"]})
 
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
    Channel subscribers push(createFutureResponse("channel"))
    redirectTo("/chat"))

  logout := method(
    Channel streamFor(session channelFutureId) ?close
    destroySession

    redirectToRoute("login"))
  
  post := method(message,
    message = ChatMessage create({created_at: Date now, body: message, user_id: session user id})
    message atPut("user_nick", session user["nick"])
    Channel post(message, [session channelFutureId]) isNil ifFalse(message asJson))

  updates := method(Channel streamFor(session channelFutureId))

### Private slots ###

  isLoggedIn := method(session ?user isNil not)

  requireAuth := method(
    isLoggedIn ifFalse(Exception raise("authRequired")))
)
