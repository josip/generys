Controller := Object clone do (
  request       ::= nil
  response      ::= nil
  params        ::= nil
  session       ::= nil
  private       ::= false
  privateSlots  ::= list()
  beforeFilters ::= list()
  afterFilters  ::= list()
  targetAction  ::= nil

  init := method(
    request = nil
    response = nil
    params = nil
    session = nil
    private = false
    privateSlots = list()
    beforeFilters = list()
    afterFilters = list()
    targetAction = nil
    
    Generys controllers appendIfAbsent(self))
    
  beforeFilter := method(filter, options, self beforeFilters append(options merge({filter: filter})))
  afterFilter  := method(filter, options, self afterFilters append(options merge({filter: filter})))

  doFilters := method(filters,
    filters foreach(filter,
      filter["only"] ?contains(self targetAction) ifFalse(continue)
      filter["except"] ?contains(self targetAction) ifTrue(continue) 

      if(filter["filter"] type == "Sequence",
        self perform(filter["filter"]),
        self doMethod(filter["filter"]))))

  doBeforeFilters := method(doFilters(self beforeFilters))
  doAfterFilters  := method(doFilters(self afterFilters))

  accepts := method(
    call message arguments map(arg, arg asString) contains(request requestMethod) ifFalse(
      Exception raise("wrongRequestMethod")))

  isPOST        := lazySlot(request requestMethod == "POST")
  isGET         := lazySlot(request requestMethod == "GET")
  isPUT         := lazySlot(request requestMethod == "PUT")
  isDELETE      := lazySlot(request requestMethod == "DELETE")
  isAjaxRequest := lazySlot(request headers["x-requested-with"] asLowercase == "xmlhttprequest")

  cacheFor := method(dur,
    response setHeader("Cache-Control", "max-age=" .. dur .. ", must-revalidate"))

  dontCache := method(
    response setHeader("Expires", Date fromNumber(0) asHTTPDate)
    response setHeader("Cache-Control", "no-cache, no-store"))

  forceDownload := method(filename,
    response setHeader("Content-Disposition", "attachment; filename=" .. filename))
  
  redirectTo := method(url, statusCode,
    # 302 = Temporary redirect
    statusCode ifNil(statusCode = 302)
    response statusCode = statusCode
    url containsSeq("http") ifFalse(
      url = Generys serverURL .. url)
    response setHeader("Location", url)
    nil)
  
  createFutureResponse := method(name,
    futureId := session sessionId .. "-" .. name
    FutureResponse at(futureId) isNil ifFalse(
      return FutureResponse at(futureId))
    
    session setSlot(name .. "FutureId", futureId)
    FutureResponse clone setName(futureId))
  
  getFutureResponse := method(name, FutureResponse at(session sessionId .. "-" .. name))
)
