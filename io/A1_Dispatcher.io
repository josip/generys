HttpServer

Dispatcher := Object clone do(
//metadoc Dispatcher category Networking
/*metadoc Dispatcher description
An HTTP request dispatcher, it is responsible for selecting right route depending on the requested path and finalize rendering - activating the right ResponseFormatter.
*/

  _routeCache := Map clone
  //doc Dispatcher handleRequest(request, response) Prepares path, calls dispatch() and formats response.
  handleRequest := method(req, resp,
    log info("Processing request #{req path}")

    req path = if((req path exSlice(-1) == "/") and(req path size > 1),
      req path exSlice(0, -1),
      req path)

    resp body = self formatResponse(self dispatch(req, resp), req, resp))
  
  //doc Dispatcher dispatch(request, response[, candidateAt]) Selects right route and activates it.
  dispatch := method(req, resp, candidateAt,
    if(self _routeCache hasKey(req path),
      route := self _routeCache[req path]
    ,
      candidates := Generys routes select(respondsTo(req path, req requestMethod))
        candidates isEmpty ifTrue(return Error with("noRoute"))

      candidateAt ifNil(candidateAt = 0)
      route := candidates at(candidateAt)
      route ifNil(return Error with("noRoute"))
      self _routeCache atPut(req path, route)
    )
    
    req activatedRoute := route
    
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
      obj = Generys controllers[controllerName]

      obj ifNil(
        log error("Route #{route pattern} requires non-existing controller '#{controllerName}'")
        return(Error with("noController")))

      slotName = route action interpolate(mappedValues asObject)
      #(slotName[0] == ":"[0]) ifTrue(slotName = mappedValues[slotName exSlice(1)])
      
      (obj ?privateSlots ?contains(slotName) or(slotName[0] asCharacter == "_")) ifTrue(
        log debug("Route #{route pattern} tried to activate private slot '#{slotName}'")
        return(Error with("noSlot")))

      obj = obj cloneWithoutInit\
        setResponse(resp)\
        setRequest(req)\
        setParams(req parameters)\
        setTargetAction(slotName)
    )
    
    #(slotName isNil or object hasSlot(slotName) not) ifTrue(return Error with("noSlot"))
    (slotName == nil or(obj hasSlot(slotName) not)) ifTrue(
      log debug("Route #{route pattern} specified missing slot '#{slotName}'")
      return(Error with("noSlot")))

    slotResp := nil
    e := try(
      slotIsBlock := obj getSlot(slotName) type == "Block"
      args := if(slotIsBlock,
        obj getSlot(slotName) argumentNames map(arg, mappedValues[arg]),
        mappedValues)
      
      obj ?doBeforeFilters(args)
      slotResp = if(slotIsBlock,
        obj ?performWithArgList(slotName, args),
        obj getSlot(slotName))
      obj ?doAfterFilters([slotResp])
      obj ?session ?save)

    # We can't return from catch block, therefor
    # we have to use this little dirty trick
    # (other exceptions are handled by ResponseFormatter)
    _skipRoute := false
    e catch(_skipRoute = e ?error == "skipRoute")
    _skipRoute ifTrue(
      log info("Skipping route #{route pattern} for request #{req path}")
      return(tailCall(req, resp, candidateAt + 1)))

    if(e, e, slotResp))

  //doc Dispatcher formatResponse(controllerResponse, request, response) Activates ResponseFormatter for controllerResponse.
  formatResponse := method(ctrlResp, req, resp,
    rtype := ctrlResp type
    rformatters := Generys formatters reverse
    
    formatter := rformatters select(f,
      (f ?respondsToType == rtype) or (f ?respondsToTypes contains(rtype)))
    formatter isEmpty ifTrue(
      formatter := rformatters select(f, f test(ctrlResp)))

    if(formatter isEmpty,
      ctrlResp asString,
      formatter first format(ctrlResp, resp, req)))
)