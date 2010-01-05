FutureResponse := Object clone do(
//metadoc FutureResponse category Networking
//metadoc FutureResponse description FutureResponse is an <em>class</em> for working with HTTP pooling.
  name        ::= nil
  socket      ::= nil
  body        ::= nil
  queue       ::= nil
  limit       ::= 1

  init := method(
    self queue = []
    self)
  
  //doc FutureResponse send(message) Appends message to the queue.
  send := method(msg, self queue append(msg); self)
  
  //doc FutureResponse prepareData() Converts data to JSON array and empties queue. Returns JSON string.
  prepareData := method(
    data := "[" .. (self queue join(",")) .. "]"
    self queue removeAll
    data)
  
  //doc FutureResponse close() Closes socket and removes <code>self</code> from <code>Generys futureResponses</code>.
  close := method(
    log debug("Closed FutureResponse '#{self name}'")
    self closeSocket
    Generys futureResponses removeAt(self name))
  
  //doc FutureResponse closeSocket() Closes only socket.
  closeSocket := method(
    self socket ?_close; self socket ?close
    self socket = nil
    self)
  
  //doc FutureResponse flush() Calls <code>Generys prepareData</code> and writes the data to the client.
  flush := method(
    if(self ?socket isOpen,
      self socket write(self prepareData); true,
      false
    ))
  
  //doc FutureResponse finish() Flushes the data and closes socket.
  finish := method(self flush ifTrue(self closeSocket))
)
