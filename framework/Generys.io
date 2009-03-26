#!/usr/bin/env io

HttpServer
IoExtensions

log := method(
  allowed := Generys log_level
  log_symbols := {debug := "#", error := "!", info := "-"}

  (allowed == "none") ifTrue(return false)

  level   := call argAt(0) argAt(0) name exSlice(1, -1)
  message := call argAt(0) argAt(1) name exSlice(1, -1) interpolate(call sender)
  symbol  := log_symbols at(level)

  log_keys := log_symbols keys
  if((allowed == "all") or (log_keys indexOf(allowed) <= log_keys indexOf(level)),
    " #{symbol} #{message}" interpolate println
  )
)

Generys := HttpServer clone do (
  routes      := List clone
  controllers := List clone
  exceptionController := Controller cloneWithoutInit do(
    name    = "Exceptions"
    private = true
    init    = nil
  )

  start = method(
    log(info = "You can find Generys on route #{host} at mile #{port}")
    super(start)
  )

  renderResponse := method(req, resp,
    log(info = "Processing request #{req path}")
    req path = if((req path exSlice(-1) == "/") and(req path size > 1),
      req path exSlice(0, -1),
      req path
    )

    hasRoute := false
    routes foreach(route,
      matches := route mapToPath(req path)
      if(matches not, matches = Map clone)

      if((req path == route pattern) or((matches values remove(nil) size > 0) and(matches keys sort == route namedParts sort)),
        log(debug:="Activating route #{route pattern} for #{req path}"); hasRoute = true,
        continue
      )

      source := route
      slotName := "responseMethod"

      source getSlot(slotName) ifNil(
        controllerName := if(route ?controller, route controller, return false)
        (controllerName exSlice(0, 1) == ":") ifTrue(
          controllerName = matches at(controllerName exSlice(1))
        )

        slotName = if(route ?action, route action, "index")
        (slotName exSlice(0, 1) == ":") ifTrue(
          slotName = matches at(slotName exSlice(1))
        )

        source = controllers select(controller,
          (controller name == controllerName) and (controller private == false)
        ) at(0)

        source ifNil(handleException("brokenRoute", resp, req); break)
        source = source cloneWithoutInit setResponse(resp) setRequest(req) setParams(req parameters asObject)
      )

      yield

      source hasSlot(slotName) ifTrue(
        if(source ?privateSlots ?contains(slotName),
          log(error:="Client requested private method, #{source name}##{slotName}")
          handleException("noRoute", resp, req)
        )
      
        (slotName == "responseMethod") ifTrue(
          matches atPut("response", resp)
          matches atPut("request", req)
        )
        slotArgs := source getSlot(slotName) argumentNames map(arg, matches at(arg))

        e := try(
          controllerResp := source performWithArgList(slotName, slotArgs)
          if(controllerResp == Controller SKIP_ME,
            hasRoute = Controller SKIP_ME,
            resp body appendSeq(parseResponse(resp, controllerResp))
          )
        )
        
        # We have to "continue" from this context as it would have no effect
        # if used within try()
        (hasRoute == Controller SKIP_ME) ifTrue(
          hasRoute = false
          log(debug:="Skipping elected route #{route pattern} for #{req path}")
          continue
        )

        e catch(Exception,
          log(error:="Cought exception #{e error} while rendering #{req path}")
          handleException(e, resp, req)
        )
      )
      break
    )

    hasRoute ifFalse(handleException("noRoute", resp, req))
  )

  parseResponse := method(httpResp, ctrlResp,
    respType := ctrlResp type
    (respType == "Map" or(respType == "List")) ifTrue(
      httpResp contentType = "text/javascript"
      return ctrlResp asJson
    )
    (respType == "File") ifTrue(
      Path isPathAbsolute(ctrlResp path) ifFalse(
        ctrlResp path = Generys publicDir .. ctrlResp path
      )
      return serveFile(ctrlResp, httpResp)
    )

    ctrlResp
  )
  
  serveFile := method(file, httpResp, 
    file exists ifFalse(
      raise Exception("notFound")
    )
    if(Generys x_sendfile_header,
      httpResp contentType = nil
      httpResp setHeader("X-Sendfile", file path)
      return "",

      # TODO: Get MIME type
      file openForReading
      contents := file contents
      file close
      return contents
    )
  )

  handleException := method(e, resp, req,
    (e type == "Sequence") ifTrue(
      error := e
      e = Exception clone
      e error := error
    )

    ec := Generys exceptionController clone setResponse(resp) setRequest(req)
    if(ec hasSlot(e error),
      log(error:="Activating handler for '#{e error}' exception")
      resp body appendSeq(ec perform(e error, e))
    ,
      log(error:="No handler for '#{e error}' exception; showing exception to user")
      resp status = 500
      resp body appendSeq("An unknow error occured:<br/><pre>#{e}</pre>" interpolate)
    )
  )
)
Generys clone := Generys
