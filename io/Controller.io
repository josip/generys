Controller := Object clone do (
//metadoc Controller category Networking
/*metadoc Controller description
Controller provides methods which respond to certain HTTP paths. Router connects paths to accompanying contollers.

Slots whose names begins with underscore are considered "private" and will never be activated by Dispatcher.
When Dispatcher activates an slot it maps Route's variables and HTTP POST/GET query parameters to slot's argument names. Parameters not bounded to arguments all available in <code>params</code> slot. Depending on the type of object which was returned the right ResponseFormatter will be activated - returning Map or List will automatically convert it into JSON format and set appropriate value for <em>Content-Type</em> header.
<pre><code>
ZooController := Controller clone do(
  visitors        := list()
  banedVisitors   := list()
  state           := "closed"

  beforeFilter("_zooShouldBeOpen", {except: "open"})
  beforeFilter("_zooShouldBeClosed", {only: "close"})
  beforeFilter("_requireNoBan", {only: ["visit", "buyToy"]})
  
  open := method(
    self state = "open"
    "Zoo open!")
  
  close := method(
    self state = "closed"
    "Zoo is closed!")
    
  visit := method(id,
    self visitors append(id)
    self session visits = if(self session ?visits isNIl,
      1, self session visits + 1)
    
    self redirectToRoute("zooEntrance"))
  
  buyToy := method(id, toy,
    self visitors select(== id) first
    self session toys append(toy))
  
  _zooShouldBeOpen := method(
    (self state == "open") ifFalse(Exception raise("zooClosed")))
  
  _zooShouldBeClosed := method(
    (self state == "closed") ifFalse(Exception raise("zooOpen")))
  
  _requireNoBan := method(
    (self banedVisitors))
)</code></pre>*/
  //doc Controller request Holds HttpRequest object of current request.
  request       ::= nil
  //doc Controller response Holds HttpResponse object.
  response      ::= nil
  //doc Controller params A Map of all parameters that came in with request. 
  params        ::= nil
  //doc Controller private If set to <code>true</code>, Dispatcher will never call slots from this controller.
  private       ::= false
  //doc Controller privateSlots List of private slots, you can add names of slots whose names don't begin with an underscore.
  privateSlots  ::= nil
  //doc Controller beforeFilters List of <em>before</em> filters. Use <code>Generys beforeFilter</code> to append new filter to controller.
  beforeFilters ::= nil
  #doc Controller afterFilters List of <em>after</em> filters. Use <code>Generys afterFilter</code> to append new filter to controller.
  afterFilters  ::= nil
  #doc Controller targetAction Name of the slot which was first called (the one specified in route for current request) 
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
  
  /*doc Controller beforeFilter(slotName, options)
  Adds method to list of methods which will be called before targeted slot (one defined in route) gets called.
  <code>options</code> is optional argument, which can contain list of slots before which filter shouldn't be called.
  Filter will get the same arguments as targeted slot.*/
  beforeFilter := method(filter, options, 
    options ifNil(options = Map clone)
    self beforeFilters append(options merge({filter: filter})))

  /*doc Controller afterFilter(filter, options)
  Adds a method to list of methods which will be called after target slot (one defined by rotue) is called.
  When called first argument will be response by targeted slot.
  For more details take a look at <code>Controller beforeFilter</code>. */
  afterFilter  := method(filter, options,
    options ifNil(options = Map clone)
    self afterFilters append(options merge({filter: filter})))

  //doc Controller doFilters(filters, args) Performs all filters with given argments. Returns nil.
  doFilters := method(filters, args,
    filters foreach(filter,
      filter["only"] ?contains(self targetAction) ifFalse(continue)
      filter["except"] ?contains(self targetAction) ifTrue(continue) 

      if(filter["filter"] type == "Sequence",
        self performWithArgList(filter["filter"], args),
        self doMethod(filter["filter"]))); nil)

  //doc Controller doBeforeFilters Performs all <code>beforeFilters</code>
  doBeforeFilters := method(args, doFilters(self beforeFilters, args))
  //doc Controller doAfterFilters Performs all <code>afterFilters</code>
  doAfterFilters  := method(args, doFilters(self afterFilters, args))

  /*doc Controller accepts(httpVerb, ...)
  Raises <code>wrongRequestMethod</code> exception if current request's HTTP verb isn't listed.*/ 
  accepts := method(
    call message arguments map(asString) contains(request requestMethod) ifFalse(
      Exception raise("wrongRequestMethod")))

  //doc Controller isPOST Returns <code>true</code> if current is made with POST.
  isPOST        := lazySlot(self request requestMethod == "POST")
  //doc Controller isGET Returns <code>true</code> if current is made with GET.
  isGET         := lazySlot(self request requestMethod == "GET")
  //doc Controller isPUT Returns <code>true</code> if current is made with PUT.
  isPUT         := lazySlot(self request requestMethod == "PUT")
  //doc Controller isDELETE Returns <code>true</code> if current is made with DELETE.
  isDELETE      := lazySlot(self request requestMethod == "DELETE")
  //doc Controller isHEAD Returns <code>true</code> if current is made with HEAD.
  isHEAD        := lazySlot(self request requestMethod == "HEAD")
  /*doc Controller isAjaxRequest
  Returns <code>true</code> if current is made via XMLHttpRequest. (X-Requested-With header has to be set).
  Note that all header names in <code>self request headers</code> are uppercased and dashes (-) are replaced with underscores.*/
  isAjaxRequest := lazySlot(self request headers["X_REQUESTED_WITH"] asLowercase == "xmlhttprequest")
  //doc Controller isWebSocket Returns <code>true</code> if request is made via WebSocket protocol.
  isWebSocket   := lazySlot(
    self isGET\
      and(self request headers["UPGRADE"] asLowercase == "websocket")\
      and(self request headers["CONNECTION"] asLowercase == "upgrade"))

  //doc Controller setStatusCode(code) Sets status code.
  setStatusCode := method(code, self response statusCode = code; self)

  //doc Controller cacheFor(duration) Sets <em>Cache-Control</em> to cache current response for <code>duration</code>.
  cacheFor := method(dur,
    self response setHeader("Cache-Control", "max-age=" .. dur .. ", must-revalidate"))

  //doc Controller dontCache Disables client-side cache for current request. 
  dontCache := method(
    self response setHeader("Expires", Date fromNumber(0) asHTTPDate)
    self response setHeader("Cache-Control", "no-cache, no-store"))

  /*doc Controller forceDownload(filename)
  Instructs browser to show "Save as" dialog for current request. <code>filename</code> will be shown to user.*/
  forceDownload := method(filename,
    self response setHeader("Content-Disposition", "attachment; filename=" .. filename)
    if(filename type == "File", file, self))

  /*doc Controller redirectTo(url[, statusCode])
  Redirects client to provided URL. By default, status code 302 is being used.
  Note that by HTTP standard, URL should be complete (<em>http://...</em>, not just <em>/cars/all</em>),
  you can use <code>(Generys serverURL) .. (Generys config urlPrefixPath)</code> for that.*/
  redirectTo := method(url, anStatusCode,
    # 302 = Temporary redirect
    anStatusCode ifNil(anStatusCode = 302)
    self setStatusCode(anStatusCode)
    
    #url containsSeq("http") ifFalse(url = Generys serverURL .. Generys config urlPrefixPath .. url)
    self response setHeader("Location", url)
    "")

  /*doc Controller redirectToRoute(routeName[, routeParams])
  Redirect client to URL at which route will be activated.
  <code>routeParams</code> will be passed to <code>Route interpolate</code>.*/
  redirectToRoute := method(routeName, params,
    params ifNil(params = Map clone)
    
    route := Generys routes select(name == routeName) first
    route ifNil(Exception raise("Could not find route named '#{routeName}'" interpolate))
    
    self redirectTo(route interpolate(params)))
  
  /*doc Controller createFutureResponse(name)
  Creates FutureResponse with given name, for which you have to make sure is unique.
  If another FutureResponse with same name already exists, it will be returned.*/
  createFutureResponse := method(name,
    Generys futureResponses hasKey(name) ifTrue(
      return(Generys futureResponses[name]))

    FutureResponse clone setName(name))
  //doc Controller getFutureResponse(name) Returns FutureResponse with provided name. Otherwise <code>nil</code>.
  getFutureResponse := method(name, Generys futureResponses[name])

  /*doc Controller createWebSocket(name[, handler])
  Creates WebSocket with given name and assings handler class (if provided).
  If another WebSocket with the same name already exists, it will be closed and new a one will be created.*/
  createWebSocket := method(name, handler,
    Generys webSockets hasKey(name) ifTrue(Generys webSockets[name] close)
    handler ifNil(handler = self)

    WebSocket with(name, self request, self response) setHandler(handler))
  //doc Controller getWebSocket(name) Returns WebSoocket with provided name. <code>nil</code> otherwise.
  getWebSocket := method(name, Generys webSockets[name])

  //doc Controller session Returns session object.
  session ::= method(
    _session := Generys getSession(self request, self response)
    _session isNil ifFalse(self session = _session)
    _session)

  //doc Controller destroySession Destroys all session data and returns empty one.
  destroySession := method(
    Generys sessions removeAt(self session sessionId))

  //doc Controller view(path) Alias for <code>HTML fromFile</code>. Value of <code>Generys root</code> is prepended to <code>path</code>.
  view := method(path,
    HTML fromFile((Generys root) .. "/" .. path))
)

ExceptionsController := Controller cloneWithoutInit do(
/*metadoc ExceptionsController description
Default controller which is used for exception handling, clone this controller for custom exception controllers. */
  //doc ExceptionsController private This controller is considered <em>private</em>, Dispatcher will never activate it.
  private = true

  //doc ExceptionsController noExceptionHandler(error) This slot will be called if required slot is not defined.
  noExceptionHandler := method(e,
    self setStatusCode(500)

    if(Generys config env == "dev",
      "An unknown error occured:<br/><pre>#{e}</pre>" interpolate,
      "An unknown error occured."
    ))

  //doc ExceptionsController notFound(error) Handler for 404 errors.
  notFound := method(e,
    self setStatusCode(404)
    "<h1>Not found (e#404)</h1>")
  
  //doc ExceptionsController noSlot(error) Alias for <code>ExceptionsContoller notFound</code>.
  noSlot := getSlot("notFound")
  
  //doc ExceptionsController noRoute(error) Alias for <code>ExceptionsContoller noRoute</code>.
  noRoute := getSlot("notFound")

  //doc ExceptionsController internalError(error) Handler for 500 errors.
  internalError := method(e,
    self setStatusCode(500)
    "<h1>Internal server error (e#500)</h1>")
  
  //doc ExceptionsController wrongRequestMethod(error) Alias for <code>ExceptionsContoller internalError</code>.  
  wrongRequestMethod := getSlot("internalError")
)