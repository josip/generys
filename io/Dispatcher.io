HttpServer

Dispatcher := Object clone do(
  handleRequest := method(req, resp,
    log info("Processing request #{req path}")

    req path = if((req path exSlice(-1) == "/") and(req path size > 1),
      req path exSlice(0, -1),
      req path)

    resp body = self formatResponse(self dispatch(req, resp), req, resp))

  dispatch := method(req, resp, candidateAt,
    candidates := Generys routes select(respondsTo(req path, req requestMethod))
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
      obj = Generys controllers[controllerName]

      obj ifNil(
        log error("Route #{route} requires non-existing controller '#{controllerName}'")
        return Error with("noController"))

      slotName = route action interpolate(mappedValues asObject)
      #(slotName[0] == ":"[0]) ifTrue(slotName = mappedValues[slotName exSlice(1)])
      
      (obj ?privateSlots ?contains(slotName) or(slotName[0] asCharacter == "_")) ifTrue(
        log debug("Route #{route} tried to activate private slot '#{slotName}'")
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
        slotResp = obj getSlot(slotName) /*?interpolate(args asObject)*/)
      obj ?doAfterFilters([slotResp])
      obj ?session ?save)

    _skipRoute := false
    e catch(_skipRoute = e ?error == "skipRoute")
    _skipRoute ifTrue(
      log info("Skipping route #{route}")
      return(self dispatch(req, resp, candidateAt + 1)))

    if(e, e, slotResp))

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