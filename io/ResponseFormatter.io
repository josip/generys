ResponseFormatter := Object clone do(
  respondsToType ::= nil
  respondsToTypes ::= list()
  
  init := method(Generys formatters appendIfAbsent(self))
  test := method(resp, false)
  format := method(resp, resp asString)
)

# Note that first defined formatter will be tested last
ResponseFormatter clone do(
  respondsToTypes = ["Error", "Exception"]
  format := method(error, resp, req,
    if(error type == "Exception",
      name := error error,
      name := error message)
    #error isKindOf(Sequence) ifTrue(error = Error with(error))

    log error("Cought exception: \"#{name}\" while rendering #{req path}")
    log debug("#{error}")
    log debug("#{error coroutine}")

    excpCtrl := Generys ExceptionsController clone setRequest(req) setResponse(resp)
    if(excpCtrl hasSlot(name),
      log error("Activating handler for '#{name}' exception")
      excpCtrl perform(name, error)
    ,
      log error("No handler for \"#{name}\" exception")
      excpCtrl noExceptionHandler(error)
    )))

ResponseFormatter clone do(
  respondsToType = "File"
  format := method(file, resp,
    if(Generys config useXSendfileHeader,
      resp contentType = ""
      resp setHeader("X-Sendfile", file path)
      return ""
    ,
      resp body = ""
      resp contentType = file mimeType
      resp contentType ifNil(
        resp contentType = "application/octet-stream"
        log error("Streaming file with unknown extension (#{file path})"))
      resp setHeader("Last-Modified", file lastDataChangeDate asHTTPDate)

      # Write HTTP headers
      resp send
      
      file streamTo(resp socket)
      
      # We need to override -send method which
      # would otherwise append HTTP headers to both
      # beninning and the end of the file
      resp send = block(file close)
      return "")))

ResponseFormatter clone do(
  respondsToType = "FutureResponse"
  format := method(futureResp, resp,
    if((Generys futureResponses hasKey(futureResp name)) and (futureResp queue isEmpty not),
      futureResp setSocket(resp socket) prepareData
    ,
      Generys futureResponses atPut(futureResp name, futureResp)
      resp socket _close := resp socket getSlot("close")
      resp socket setSlot("close", method())
      futureResp setSocket(resp socket)
      return "")))

ResponseFormatter clone do(
  respondsToType = "nil"
  format := method(nothing, resp,
    resp statusCode = 404
    ""))

ResponseFormatter clone do(
  respondsToTypes = ["true", "false"]
  format := method(state, resp,
    if(state, resp statusCode = 200, resp statusCode = 500)
    ""))

ResponseFormatter clone do(
  respondsToType = "SGMLElement"
  format := method(element, resp,
    docType := element docType
    docType ifNil(docType = "<!DOCTYPE html>\r\n")
    docType .. (element asString)))

ResponseFormatter clone do(
  respondsToType = "Number"
  format := method(statusCode, resp,
    resp statusCode = statusCode
    ""))

ResponseFormatter clone do(
  respondsToTypes = ["List", "Map"]
  format := method(obj, resp,
    resp contentType = "application/json"
    obj asJson))

ResponseFormatter clone do(
  respondsToType = "Sequence"
  format := method(str, resp, str))