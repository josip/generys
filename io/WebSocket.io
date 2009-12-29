# Based upon http://github.com/Guille/node.websocket.js

WebSocketHandler := Object clone do(
  socket          ::= nil
  session         ::= nil  
  isAuthenticated ::= false

  socketConnect   := method()
  socketClose     := method()
  processMessage  := method()

  authenticate := method(sessionId, 
    Generys sessions hasKey(sessionId) ifFalse(return(false))
    
    self setSession(Generys sessions[sessionId])
    self isAuthenticated = true)

  processData := method(data,
    self isAuthenticated ifFalse(
      data = Yajl parseJson(data)
      self authenticate(data["sessionId"]) ifTrue(
        self processData = method(data,
          self processMessage(Yajl parseJson(data)))
        )))
)

WebSocket := Object clone do(
  name        ::= nil
  socket      ::= nil
  handshaked  ::= false
  origins     ::= "*"
  resource    ::= "default"

  requestHeaders  ::= nil
  # NOTE: We can't use Map becouse the order is not preserved
  responseHeaders := [
    "Upgrade: WebSocket",
    "Connection: Upgrade",
    "WebSocket-Origin: #{origin}",
    "WebSocket-Location: #{location}"]

  handler       ::= nil

  with := method(name, request, response,
    self clone\
      setName(name)\
      setSocket(response socket)\
      setRequestHeaders(request headers)\
      setResource(request path)\
      patchResponse(response))

  patchResponse := method(response,
    response do (
      send = method()
      socket _close := socket getSlot("close")
      socket close = method()
    )
    self)

  setHandler := method(object, 
    self handler = object
    self handler setSocket(self)
    self)

  verifyHeaders := method(
    self requestHeaders keys containsAll(["UPGRADE", "CONNECTION", "HOST", "ORIGIN"]) ifFalse(return(false))
    self requestHeaders values select(isEmpty) size == 0)
  
  verifyOrigin := method(origin,
    (self origins type == "Sequence") ifTrue(
      return(self origins == "*" or(self origins == origin)))
    
    self origins contains(origin))
  
  handshake := method(
    self verifyHeaders ifFalse(
      log debug("Closed WebSocket due to bad headers. Received headers:" .. (self requestHeaders asObject))
      self close
      return(self))
    self verifyOrigin(self requestHeaders["ORIGIN"]) ifFalse(
      log debug("Closed WebSocket due to wrong origin.")
      self close
      return(self))

    shake := Sequence clone asUTF8 asMutable
    shake appendSeq("HTTP/1.1 101 Web Socket Protocol Handshake\r\n")
    origin := requestHeaders["ORIGIN"]
    protocol := if(Generys config port == 443, "wss", "ws")
    location := "#{protocol}://#{Generys config host}:#{Generys config port}#{self resource}" interpolate
    shake appendSeq(self responseHeaders join("\r\n") interpolate)
    shake appendSeq("\r\n\r\n")

    self socket write(shake asUTF8)
    self socket readBuffer = self socket readBuffer exSlice(0, 0)
    
    self handshaked = true
    self handler ?handleSocketConnect

    self listen

    self)

  send := method(data,
    e := try(
      #log debug("Pushing #{data} via WebSocket")
      self socket write(self _messageBeginMarker)
      self socket write(data asString asUTF8)
      self socket write(self _messageEndMarker)
      return(self)
    )
    e catch(
      log debug("WebSocket to #{self socket host} has been closed while pushing new data.")
      self close))
  
  listen := method(
    self socket isOpen ifFalse(
      return(self close))

    while(self socket read,
      self socket isOpen ifFalse(
        return(self close))

      buffer := self socket readBuffer asUTF8
      # Io won't clear the buffer automagically
      self socket readBuffer = self socket readBuffer exSlice(0, 0)
      chunks := buffer split(self _messageChunkSeparator)

      #if(chunks size > 0,
      #  log debug("Got #{chunks size} chunks via WebSocket from #{self socket host}"))
      
      chunks foreach(chunk,
        #log debug("Parsing chunk #{n}, size: #{chunk at(2)}, data: #{chunk}")
        (chunk at(0) == 0) ifFalse(
          log debug("WebSocket dropped because data was incorrectly framed by UA.")
          return(self socket close))

        (chunk size > 2) ifTrue(
          e := try(
            self handler processData(chunk exSlice(1, -1))) 
          e catch(
            log debug("Error in processData #{e}")))))

    tailCall)

  close := method(
    try(self handler socketClose)
    self handler = nil
    self socket _close
    Generys webSockets removeAt(self name))

  _messageBeginMarker     := Sequence clone append(0x0000)
  _messageEndMarker       := Sequence clone append(0xFFFF)
  _messageChunkSeparator  := Sequence clone append(0xFFFD)
)