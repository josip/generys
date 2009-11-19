FutureResponse := Object clone do(
  name        ::= nil
  socket      ::= nil
  body        ::= nil
  queue       ::= nil
  limit       ::= 1
  
  init := method(
    log debug("Created new FutureResponse")
    self queue = []; self)

  append := method(msg, self queue append(msg); self)
  push := getSlot("append")
  
  at := method(name, Generys futureResponses[name])

  close := method(
    log debug("Closed FutureResponse '#{self name}'")
    self closeSocket
    Generys futureResponses removeAt(self name))
  
  closeSocket := method(
    self socket ?_close; self socket ?close
    self socket = nil
    self)
  
  prepareData := method(
    data := self queue asJson
    self queue removeAll
    data)
  
  flush := method(
    if(self ?socket isOpen,
      self socket write(self prepareData); true,
      false
    ))
  
  finish := method(self flush ifTrue(self closeSocket))
)
