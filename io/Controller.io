Controller := Object clone do (
  request       ::= nil
  response      ::= nil
  params        ::= nil
  private       ::= false
  privateSlots  ::= nil
  beforeFilters ::= nil
  afterFilters  ::= nil
  targetAction  ::= nil

  init := method(
    self request  = nil
    self response = nil
    self params   = nil
    self private  = false
    self privateSlots   = list()
    self beforeFilters  = list()
    self afterFilters   = list()
    self targetAction   = nil
    
    Generys controllers appendIfAbsent(self))
  
  # TODO: Move all the rendering code (formatResponse etc.) from Generys
  # to Controller, that will allow re-rendering the controller from within
  # ResponseFormatters themselves (usecase: Exceptions ResponseFormatter) 
  #render := method()
  
  #private := method(
  #  self setSlot = self updateSlot = method(name, value,
  #    self privateSlots appendIfAbsent(name)
  #    super(name, value))
  #  )
  
  beforeFilter := method(filter, options, 
    options ifNil(options = Map clone)
    self beforeFilters append(options merge({filter: filter})))

  afterFilter  := method(filter, options,
    options ifNil(options = Map clone)
    self afterFilters append(options merge({filter: filter})))

  doFilters := method(filters, args,
    filters foreach(filter,
      filter["only"] ?contains(self targetAction) ifFalse(continue)
      filter["except"] ?contains(self targetAction) ifTrue(continue) 

      if(filter["filter"] type == "Sequence",
        self performWithArgList(filter["filter"], args),
        self doMethod(filter["filter"]))))

  doBeforeFilters := method(args, doFilters(self beforeFilters, args))
  doAfterFilters  := method(args, doFilters(self afterFilters, args))

  accepts := method(
    call message arguments map(asString) contains(request requestMethod) ifFalse(
      Exception raise("wrongRequestMethod")))

  isPOST        := lazySlot(self request requestMethod == "POST")
  isGET         := lazySlot(self request requestMethod == "GET")
  isPUT         := lazySlot(self request requestMethod == "PUT")
  isDELETE      := lazySlot(self request requestMethod == "DELETE")
  isHEAD        := lazySlot(self request requestMethod == "HEAD")
  isAjaxRequest := lazySlot(self request headers["X_REQUESTED_WITH"] asLowercase == "xmlhttprequest")
  isWebSocket   := lazySlot(
    self isGET\
      and(self request headers["UPGRADE"] asLowercase == "websocket")\
      and(self request headers["CONNECTION"] asLowercase == "upgrade"))

  setStatusCode := method(code, self response statusCode = code; self)

  cacheFor := method(dur,
    self response setHeader("Cache-Control", "max-age=" .. dur .. ", must-revalidate"))

  dontCache := method(
    self response setHeader("Expires", Date fromNumber(0) asHTTPDate)
    self response setHeader("Cache-Control", "no-cache, no-store"))

  forceDownload := method(filename,
    self response setHeader("Content-Disposition", "attachment; filename=" .. filename)
    if(filename type == "File", file, self))
  
  redirectTo := method(url, anStatusCode,
    # 302 = Temporary redirect
    anStatusCode ifNil(anStatusCode = 302)
    self setStatusCode(anStatusCode)
    
    #url containsSeq("http") ifFalse(url = Generys serverURL .. Generys config urlPrefixPath .. url)
    self response setHeader("Location", url)
    "")

  redirectToRoute := method(routeName, params,
    params ifNil(params = Map clone)
    
    route := Generys routes select(name == routeName) first
    route ifNil(Exception raise("Could not find route named '#{routeName}'" interpolate))
    
    self redirectTo(route interpolate(params)))
  
  createFutureResponse := method(name,
    Generys futureResponses hasKey(name) ifTrue(
      return(Generys futureResponses[name]))

    FutureResponse clone setName(name))
  getFutureResponse := method(name, Generys futureResponses[name])

  createWebSocket := method(name, handler,
    Generys webSockets hasKey(name) ifTrue(Generys webSockets[name] close)

    webSocket := WebSocket with(name, self request, self response) setHandler(handler)
    Generys webSockets atPut(name, webSocket)

    webSocket)
  getWebSocket := method(name, Generys webSockets[name])

  session ::= method(
    _session := Generys getSession(self request, self response)
    _session isNil ifFalse(self session = _session)
    _session)

  destroySession := method(
    Generys sessions removeAt(self session sessionId))

  view := lazySlot(path, HTML fromFile(path))
)
