Object do(
  Channel := Object clone do(
  subscribers := list()
  cache       := list()
  cacheSize   := 20
  
  post := method(message, exclude,
    self subscribers foreach(subscriber,
      exclude contains(subscriber name) ifFalse(subscriber push(message) finish)))

    cache push(message)
    if(cache size == cacheSize, cache removeFirst)
    
    message)
    
  streamFor := method(futureRespId,
    subscribers select(subscriber, subscriber name == futureRespId) first))

ChatController := Controller clone do(
  beforeFilter("auth", {except: {"index", "login"}})
  
  index := method(
    if(isLoggedIn, File clone with("public/chat/room.html"), redirectTo("/chat/login")))
  
  login := method(nick,
    isGET ifTrue(return File clone with("public/chat/index.html"))

    session nick := nick
    session loggedIn := true
    Channel subscribers push(createFutureResponse("channel"))
    redirectTo("/chat"))

  logout := method(
    session nick = nil
    session loggedIn = false
    Channel streamFor(session channelFutureId) ?close
    session channelFutureId = nil
    true)
  
  post := method(message,
    dontCache
    message = {id: UUID uuid, created_at: Date now, body: message, user: session nick}
    Channel post(message, {session channelFutureId})
    message asJson)
  
  updates := method(
    dontCache
    Channel streamFor(session channelFutureId))
  
  isLoggedIn := method(session ?loggedIn)
  
  auth := method(
    log debug("Requiring login for '#{self targetAction}' action")
    isLoggedIn ifFalse(Exception raise("authRequired")))
)