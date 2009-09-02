#!/usr/bin/env io

HttpServer
IoExtensions
Log

Generys := HttpServer clone do (
  version     := 0.2
  
  routes      := List clone
  
  controllers := List clone
  controllers at := method(name,
    name = name .. "Controller"
    self select(controller, controller type == name) first)
  
  formatters  := List clone
  
  config := Object clone do(
    host                := "127.0.0.1"
    port                := 8080
    logLevel            := "debug"
    poweredByHeader     := "Io/" .. System version
    useXSendFileHeader  := false
  )
  
  ExceptionsController := Controller cloneWithoutInit do(
    private = true
    init    = nil)
    
  start = method(
    host := config host
    port := config port
    
    if(self config poweredByHeader isNil not,
      self config poweredByHeader = self config poweredByHeader .. "+Generys/" .. self version)
    
    log info("You can find Generys on route #{host} at mile #{port}")
    super(start))

  renderResponse := method(req, resp,
    log info("Processing request #{req path}")
    if(self config poweredByHeader isNil not,
      resp setHeader("X-Powered-By", self config poweredByHeader))
    
    req path = if((req path exSlice(-1) == "/") and(req path size > 1),
      req path exSlice(0, -1),
      req path)

    formattedResponse := self formatResponse(self dispatch(req, resp), resp)
    resp body appendSeq(formattedResponse)
  )

  dispatch := method(req, resp,
    candidates := routes select(route, route respondsTo(req path))
    candidates isEmpty ifTrue(return Error with("noRoute"))
    
    route := candidates first
    route ifNil(return Error with("noRoute"))
    
    obj := nil
    slotName := nil
    mappedValues := route mapToPath(req path)

    if(route getSlot("responseMethod") isNil not,
      obj := route
      slotName = "responseMethod"
      mappedValues atPut("request", req)
      mappedValues atPut("response", resp)
    ,
      controllerName := route controller
      (controllerName[0] == ":"[0]) ifTrue(
        controllerName = mappedValues[controllerName exSlice(1)])
      obj = Generys controllers[controllerName]

      obj ifNil(
        log debug("Route #{route} requires non-existing controller '#{controllerName}'")
        return Error with("noController"))

      slotName = route action
      (slotName[0] == ":"[0]) ifTrue(slotName = mappedValues[slotName exSlice(1)])
      
      obj ?privateSlots ?contains(slotName) ifTrue(
        log debug("Route #{route} requires private slot '#{slotName}'")
        return Error with("noSlot"))

      obj = obj cloneWithoutInit setResponse(resp) setRequest(req) setParams(req parameters)
    )
    
    slotName ifNil(return Error with("noSlot"))
    obj hasSlot(slotName) ifFalse(return Error with("noSlot"))

    slotResp := nil
    e := try(
      args := obj getSlot(slotName) argumentNames map(arg, mappedValues[arg])
      slotResp = obj performWithArgList(slotName, args))
    e catch(Exception,
      (e error == "skipRoute") ifTrue(log info("Should skip route #{route}"))
      log error("Cought exception #{e error} while rendering #{req path}"))

    if(e, e, slotResp))

  formatResponse := method(ctrlResp, resp,
    rtype := ctrlResp type
    formatter := self formatters reverse select(f,
      (f ?respondsToType == rtype) or (f ?respondsToTypes contains(rtype)))
    formatter isEmpty ifTrue(
      formatter := self formatters reverse select(f, f test(ctrlResp)))
        
    if(formatter isEmpty,
      ctrlResp asString,
      formatter first format(ctrlResp, resp)))
)
Generys clone := Generys

ResponseFormatter