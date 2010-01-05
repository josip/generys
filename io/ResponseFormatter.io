ResponseFormatter := Object clone do(
/*metadoc ResponseFormatter description
ResponseFormatters are responsible for final shaping of the data returned by controller.
Depending on the type of the data returned by controller (ExceptionController included),
the right ResponseFormatter will be activated and the data returned by it will be sent to the browser.
*/
  //doc ResponseFormatter respondsToType Type on which ResponseFormatter should be activated.
  respondsToType ::= nil
  //doc ResponseFormatter respondsToTypes List of types to which ResponseFormatter should be activated.
  respondsToTypes ::= list()
  
  init := method(Generys formatters appendIfAbsent(self))
  
  /*doc ResponseFormatter test(controllerResponse)
  Method which will be called when no ResponseFormatter responds to given type.
  Method should return eiter <code>true</code> if it can handle given data, <code>false</code> otherwise. */
  test := method(resp, false)
  
  /*doc ResponseFormatter format(controllerResponse, httpResponse, httpRequest)
  Method which will be called on selected ResponseFormatter.
  Method should return Sequence which will be sent to the browser, as well as setting up appropriate <em>Content-Type</em> header etc.*/
  format := method(ctrlResp, resp, req, ctrlResp asString)
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

    # Tests first if specialised Exceptions controller exists, if not, use the default one.
    # We call cloneWithoutInit() on ExceptionsController becouse init method contains code
    # which appends the controller to Generys controllers, something we don't need.
    excpCtrl := Generys controllers at((req activatedRoute ?controller) .. "Exceptions") ?clone ifNil(
                ExceptionsController cloneWithoutInit)
    excpCtrl setRequest(req) setResponse(resp)

    if(excpCtrl hasSlot(name),
      log error("Activating handler for '#{name}' exception #{excpCtrl type}")
      excpCtrl perform(name, error)
    ,
      log error("No handler for '#{name}' exception in #{excpCtrl type}")
      excpCtrl noExceptionHandler(error)
    ))
)

ResponseFormatter clone do(
  respondsToType = "File"
  format := method(file, resp,
    if(Generys config useXSendfileHeader,
      resp setHeader("Content-Type", "")
      resp setHeader("X-Sendfile", file path)
      return("")
    ,
      resp body = ""
      resp contentType = file mimeType
      resp ?contentType ifNil(
        resp contentType = "application/octet-stream"
        log error("Streaming file with unknown extension (#{file path}). Add extension to File mimeTypes."))
      resp setHeader("Last-Modified", file lastDataChangeDate asHTTPDate)

      # Write HTTP headers
      resp send
      
      file streamTo(resp socket)
      
      # We need to override -send method which
      # would otherwise append HTTP headers to both
      # beninning and the end of the file
      resp send = block(send)
      return("")))
)

ResponseFormatter clone do(
  respondsToType = "FutureResponse"
  format := method(futureResp, resp,
    if((Generys futureResponses hasKey(futureResp name)) and (futureResp queue isEmpty not),
      resp contentType = "application/json"
      futureResp setSocket(resp socket) prepareData
    ,
      Generys futureResponses atPut(futureResp name, futureResp)
      resp socket _close := resp socket getSlot("close")
      resp socket setSlot("close", method())
      futureResp setSocket(resp socket)
      ""))
)

ResponseFormatter clone do(
  respondsToType = "WebSocket"
  format := method(webSocket, resp,
    Generys webSockets atPut(webSocket name, webSocket)
    webSocket handshaked ifFalse(webSocket handshake)
    "")
)

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
    docType := element ?docType
    docType ifNil(docType = "<!DOCTYPE html>\r\n")
    docType .. (element asString)))

ResponseFormatter clone do(
  respondsToType = "Number"
  format := method(statusCode, resp,
    resp statusCode = statusCode
    ""))

ResponseFormatter clone do(
  respondsToTypes = ["List", "Map", "CouchDoc"]
  format := method(obj, resp,
    resp contentType = "application/json"
    obj asJson))

ResponseFormatter clone do(
  respondsToType = "Sequence"
  format := method(str, resp, str))