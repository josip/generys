ResponseFormatter := Object clone do(
  respondsToType ::= nil
  respondsToTypes ::= List clone
  init := method(Generys formatters appendIfAbsent(self))

  test := method(resp, false)
  format := method(resp, resp asString)
)

# Note that first defined formatter will be tested last
ResponseFormatter clone do(
  respondsToTypes = {"Error", "Exception"}
  format := method(error, resp, req,
    (error type == "Exception") ifTrue(error = error error)
    error isKindOf(Sequence) ifTrue(error = Error with(error))
    
    excpCtrl := Generys ExceptionsController clone setRequest(req) setResponse(resp)
    if(excpCtrl hasSlot(error message),
      log error("Activating handler for '#{error message}' exception")
      excpCtrl perform(error message, error)
    ,
      log error("No handler for '#{error message}' exception; showing exception to user")
      resp status = 500
      "An unknow error occured:<br/><pre>#{error}</pre>" interpolate)))

ResponseFormatter clone do(
  respondsToType = "File"
  format := method(file, resp,
    if(Generys config ?useXSendfileHeader,
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
  respondsToType = "nil"
  format := method(nothing, resp,
    return ""))

ResponseFormatter clone do(
  respondsToTypes = {"true", "false"}
  format := method(state, resp,
    if(state, resp statusCode = 200, resp statusCode = 500)
    ""))

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
  respondsToTypes = {"List", "Map"}
  format := method(obj, resp,
    resp contentType = "application/json"
    obj asJson))

ResponseFormatter clone do(
  respondsToTypes = {"Sequence", "Number"}
  format := method(str, resp, str))