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
  
  private := method(
    self setSlot = self updateSlot = method(name, value,
      self privateSlots appendIfAbsent(name)
      super(name, value))
    )
  
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

  isPOST        := lazySlot(request requestMethod == "POST")
  isGET         := lazySlot(request requestMethod == "GET")
  isPUT         := lazySlot(request requestMethod == "PUT")
  isDELETE      := lazySlot(request requestMethod == "DELETE")
  isHEAD        := lazySlot(request requestMethod == "HEAD")
  isAjaxRequest := lazySlot(request headers["x-requested-with"] asLowercase == "xmlhttprequest")

  setStatusCode := method(code, response statusCode = code; self)

  cacheFor := method(dur,
    response setHeader("Cache-Control", "max-age=" .. dur .. ", must-revalidate"))

  dontCache := method(
    response setHeader("Expires", Date fromNumber(0) asHTTPDate)
    response setHeader("Cache-Control", "no-cache, no-store"))

  forceDownload := method(filename,
    response setHeader("Content-Disposition", "attachment; filename=" .. filename))
  
  redirectTo := method(url, anStatusCode,
    # 302 = Temporary redirect
    anStatusCode ifNil(anStatusCode = 302)
    statusCode(anStatusCode)
    
    #url containsSeq("http") ifFalse(url = Generys serverURL .. Generys config urlPrefixPath .. url)
    response setHeader("Location", url)
    "")

  redirectToRoute := method(routeName, params,
    params ifNil(params = Map clone)
    
    route := Generys routes select(name == routeName) first
    route ifNil(Exception raise("Could not find route named '#{routeName}'" interpolate))
    
    redirectTo(route interpolate(params)))
  
  createFutureResponse := method(name,
    futureId := session sessionId .. "-" .. name
    FutureResponse at(futureId) isNil ifFalse(
      return FutureResponse at(futureId))
    
    session setSlot(name .. "FutureId", futureId)
    FutureResponse clone setName(futureId))
  
  getFutureResponse := method(name, FutureResponse at(session sessionId .. "-" .. name))
  
  session := lazySlot(
    Generys getSession(self request, self response))

  destroySession := method(
    Generys sessions removeAt(session sessionId))

  view := method(path, self view = SGML htmlFromFile(path))
)
