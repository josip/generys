HttpServer
UUID

Generys := HttpServer clone do (
  version     := 0.2
  routes      := list()
  
  controllers := list()
  controllers at = method(name,
    name = name .. "Controller"
    self select(type == name) first)

  formatters  := list()
  sessions    := nil
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

  run := method(
    self sessions = Object getSlot(self config sessionStore) clone

    ph := self config poweredByHeader
    if(ph isNil not, ph = ph .. "+Generys/" .. self version)

    doFile(self root .. "/config/routes.io")
    doFile(self envDir .. "/init.io")

    Directory with(self root .. "/app/models") doFiles
    Directory with(self root .. "/app/controllers") doFiles
    
    self setHost(self config host)
    self setPort(self config port)

    log info("You can find Generys on route #{self config host} at mile #{self config port}")
    self start)

  renderResponse := method(req, resp,
    log info("Processing request #{req path}")
    self setPoweredByHeader(resp)
    
    req path = if((req path exSlice(-1) == "/") and(req path size > 1),
      req path exSlice(0, -1),
      req path)

    formattedResponse := self formatResponse(self dispatch(req, resp), req, resp)
    resp body appendSeq(formattedResponse)
  )

  dispatch := method(req, resp, candidateAt,
    candidates := routes select(respondsTo(req path))
    candidates isEmpty ifTrue(return Error with("noRoute"))
    
    candidateAt ifNil(candidateAt = 0)
    route := candidates at(candidateAt)
    route ifNil(return Error with("noRoute"))
    
    obj := nil
    slotName := nil
    mappedValues := route mapToPath(req path)
    req parameters foreach(k, v, mappedValues atIfAbsentPut(k, v))

    if(route getSlot("responseMethod") isNil not,
      obj := route
      slotName = "responseMethod"
      mappedValues atPut("request",   req)
      mappedValues atPut("response",  resp)
    ,
      controllerName := route controller interpolate(mappedValues asObject)
      #(controllerName[0] == ":"[0]) ifTrue(
      #  controllerName = mappedValues[controllerName exSlice(1)])
      obj = Generys controllers[controllerName]

      obj ifNil(
        log debug("Route #{route} requires non-existing controller '#{controllerName}'")
        return Error with("noController"))

      slotName = route action interpolate(mappedValues asObject)
      #(slotName[0] == ":"[0]) ifTrue(slotName = mappedValues[slotName exSlice(1)])
      
      obj ?privateSlots ?contains(slotName) ifTrue(
        log debug("Route #{route} requires private slot '#{slotName}'")
        return Error with("noSlot"))

      obj = obj cloneWithoutInit\
        setResponse(resp)\
        setRequest(req)\
        setParams(req parameters)\
        setTargetAction(slotName)
    )
    
    #(slotName isNil or object hasSlot(slotName) not) ifTrue(return Error with("noSlot"))
    slotName ifNil(return Error with("noSlot"))
    obj hasSlot(slotName) ifFalse(return Error with("noSlot"))

    slotResp := nil
    e := try(
      slotIsBlock := obj getSlot(slotName) type == "Block"
      if(slotIsBlock,
        args := obj getSlot(slotName) argumentNames map(arg, mappedValues[arg]),
        args := mappedValues)
      
      obj ?doBeforeFilters(args)
      if(slotIsBlock,
        slotResp = obj ?performWithArgList(slotName, args),
        slotResp = obj getSlot(slotName) ?interpolate(args asObject))
      obj ?doAfterFilters
      obj ?session ?save)
    
    e catch(Exception,
      (e error == "skipRoute") ifTrue(
        log info("Skipping route #{route}")
        return self dispatch(req, resp, candidateAt + 1)))

    if(e, e, slotResp))

  formatResponse := method(ctrlResp, req, resp,
    rtype := ctrlResp type
    rformatters := self formatters reverse
    
    formatter := rformatters select(f,
      (f ?respondsToType == rtype) or (f ?respondsToTypes contains(rtype)))
    formatter isEmpty ifTrue(
      formatter := rformatters select(f, f test(ctrlResp)))

    if(formatter isEmpty,
      ctrlResp asString,
      formatter first format(ctrlResp, resp, req)))
  
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
  
  setPoweredByHeader := method(resp,
    if(self config poweredByHeader isNil,
      self setPoweredByHeader = method(),
      resp setHeader("X-Powered-By", self config poweredByHeader)))
  
)
Generys clone := Generys
