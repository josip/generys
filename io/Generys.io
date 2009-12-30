Socket
Dispatcher
UUID

Generys := HttpServer clone do (
  version     := 0.2.5
  routes      := list()
  
  controllers := list()
  controllers at = method(name,
    name = name .. "Controller"
    self select(type == name) first)

  formatters  := list()
  sessions    := nil
  webSockets  := Map clone
  futureResponses := Map clone
  
  config := Object clone do(
    host                := "127.0.0.1"
    port                := 4000
    urlPrefixPath       := ""
    sessionCookieName   := "_s"
    sessionStore        := "Map"
    poweredByHeader     := "Io/" .. System version
    useXSendFileHeader  := false
    logLevel            := "debug"
    logFile             := nil
    env                 := "dev"
  )
  serverURL := lazySlot("http://#{host}:#{port}#{urlPrefixPath}" interpolate(self config))
  envDir    := lazySlot(self root .. "/config/env/" .. (self config env))

  ExceptionsController := Controller cloneWithoutInit do(
    private = true
    init    = nil)

  loadConfig := method(
    self config = (doFile((self envDir) .. "/config.json") asObject) appendProto(self config))

  #requestHandlerProto = Dispatcher
  serve := method(
    self loadConfig
    self sessions = Object getSlot(self config sessionStore) clone

    doFile(self root .. "/config/routes.io")
    doFile(self envDir .. "/init.io")

    Directory with(self root .. "/app/models") doFiles
    Directory with(self root .. "/app/controllers") doFiles
    Directory with(self root .. "/lib") doFiles

    self setHost(self config host)
    self setPort(self config port)

    log info("You can find Generys on route #{self config host} at mile #{self config port}")
    
    self start)

  renderResponse := method(req, resp,
    Dispatcher handleRequest(req, resp))

  getSession := method(req, resp,
    cookieName := self config sessionCookieName
    sessionId := req cookies[cookieName]
    
    sessionId ifNil(
      sessionId = UUID uuidRandom
      resp setCookie(cookieName, sessionId))
    self sessions[sessionId] ifNil(
      session := Object clone
      session setSlot("sessionId", sessionId)
      self sessions atPut(sessionId, session))

    self sessions[sessionId])
)
Generys clone := Generys
