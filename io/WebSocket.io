# Based upon http://github.com/Guille/node.websocket.js

WebSocketHandler := Object clone do(
//metadoc WebSocketHandler category Networking
/*metadoc WebSocketHandler description
<p>Object whose methods are called from WebSocket when connection is established, authenticated, disconnected or when an message is received.</p>
<p>Example:
<pre><code>
ChatWebSocketHandler := WebSocketHandler clone do(
  authenticate := method(sessionId,
    super(authenticate(sessionId)) ifTrue(
      self chatController := ChatController clone setSession(self session)
      self socket send({authDetails: true, user: self session user} asJson)))

  processMessage := method(msg,
    self chatController post(msg["body"]))
)
</code></pre></p>
*/
  //doc WebSocketHandler socket Holds WebSocket object.
  socket          ::= nil
  //doc WebSocketHandler session Session object.
  session         ::= nil  
  //doc WebSocketHandler isAuthenticated Shows if the client has already sent authentication cookie.
  isAuthenticated ::= false

  //doc WebSocketHandler handleSocketConnect Method which is called once WebSocket connection is established.
  handleSocketConnect   := method()
  //doc WebSocketHandler handleSocketClose Method which will be called when WebSocket connection is closed.
  handleSocketClose     := method()
  /*doc WebSocketHandler proccessMessage(message)
  Method wwhich will be called when new message arrives. First argument will be parse JSON message (Map).*/
  processMessage        := method()

  /*doc WebSocketHandler authenticate(sessionId)
    <p>Method called when authentication cookie arrives. Returns <code>true</code> if authentication succeeds.</p>
    <p>If you plan on overwriting this slot remember to call <code>super(authenticate(sessionId))</code></p>*/
  authenticate := method(sessionId, 
    Generys sessions hasKey(sessionId) ifFalse(return(false))
    
    self setSession(Generys sessions[sessionId])
    self isAuthenticated = true)

  /*doc WebSocketHandler processData(data)
  <p>Method which is directly called from WebSocket when data arrives.
  This method then, if user is authenticated calls <code>WebSocketHandler proccessMessage()</code>
  or <code>WebSocketHandler authenticate()</code> otherwise.
  </p>
  <p>It is recommended that if you'll have to overwrite this slot,
  that you do it after authentication happens (unless the authentication proccess is what you're changing).</p>*/
  processData := method(data,
    self isAuthenticated ifFalse(
      data = Yajl parseJson(data)
      self authenticate(data["sessionId"]) ifTrue(
        self processData = method(data,
          self processMessage(Yajl parseJson(data)))
        )))
)

WebSocket := Object clone do(
//metadoc WebSocket category Networking
//metadoc WebSocket description Object for working with WebSocket specification.
  //doc WebSocket name Name of the connection. It has to be unique.
  name        ::= nil
  //doc WebSocket socket Actual Socket with the client.
  socket      ::= nil
  //doc WebSocket handshaked <code>true</code> if WebSocket handshake has been completed, <code>false</code> otherwise.
  handshaked  ::= false
  //doc WebSocket origins List or string of allowed origins of requests. Defaults to "*" (all requests accepted)
  origins     ::= "*"
  //doc WebSocket resource Path at which connection has been established. (URL path, set automatticaly from <code>Controller createWebSocket</code> to the path of request).
  resource    ::= "default"
  //doc WebSocket channel Channel to which <code>self</code> is subscribed to (if any).
  channel         ::= nil

  //doc WebSocket requestHeaders Headers of the request, as given by Volcano.
  requestHeaders  ::= nil
  //doc WebSocket responseHeaders Headers which will be sent to client during handshake.
  # NOTE: We can't use Map becouse the order is not preserved
  responseHeaders := [
    "Upgrade: WebSocket",
    "Connection: Upgrade",
    "WebSocket-Origin: #{origin}",
    "WebSocket-Location: #{location}"]

  //doc WebSocket handler WebSocketHandler object whose slots will be called on certain events.
  handler       ::= nil

  //doc WebSocket with(name, httpRequest, httpResponse) Creates new WebSocket instance. 
  with := method(name, request, response,
    self clone\
      setName(name)\
      setSocket(response socket)\
      setRequestHeaders(request headers)\
      setResource(request path)\
      patchResponse(response))
  
  //doc WebSocket patchResponse(response) Disables Volcano from closing the socket.
  patchResponse := method(response,
    response do (
      send = method()
      socket _close := socket getSlot("close")
      socket close = method()
    )
    self)

  //doc WebSocket setHandler(handler) Sets <code>handler</code> slot and handler's <code>socket</code> slot.
  setHandler := method(object, 
    self handler = object
    self handler setSocket(self)
    self)

  //doc WebSocket verifyHeaders Checks if request contains all headers defined by WebSocket specification. Returns <code>false</code> if not.
  verifyHeaders := method(
    self requestHeaders keys containsAll(["UPGRADE", "CONNECTION", "HOST", "ORIGIN"]) ifFalse(return(false))
    self requestHeaders values select(isEmpty) size == 0)
  
  //doc WebSocket verifyOrigin(origin) Checks if requests origin is allowed.
  verifyOrigin := method(origin,
    (self origins type == "Sequence") ifTrue(
      return(self origins == "*" or(self origins == origin)))
    
    self origins contains(origin))
  
  //doc WebSocket handshake() Performs WebSocket handshake.
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
    try(self handler handleSocketConnect)

    self listen

    self)

  //doc WebSocket send(data) Sends data to the client. Returns <code>self</code>.
  send := method(data,
    e := try(
      self socket write(self _messageBeginMarker)
      self socket write(data asString asUTF8)
      self socket write(self _messageEndMarker)
      return(self)
    )
    e catch(
      log debug("WebSocket to #{self socket host} has been closed while sending data.")
      self close)
    self)
  
  //doc WebSocket listen() Internal method which acts on data received by client.
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

  //doc WebSocket close() Closes socket and removes <code>self</code> from <code>Generys webSockets</code>.
  close := method(
    try(self handler handleSocketClose)
    self handler = nil
    self socket _close
    self channel ?unsubscribe(self)
    Generys webSockets removeAt(self name))

  _messageBeginMarker     := Sequence clone append(0x0000)
  _messageEndMarker       := Sequence clone append(0xFFFF)
  _messageChunkSeparator  := Sequence clone append(0xFFFD)
)