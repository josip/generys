FutureResponse := Object clone do(
  name        ::= nil
  socket      ::= nil
  body        ::= nil
  queue       ::= nil
  limit       ::= 1

  init := method(
    self queue = []
    self)

  send := method(msg, self queue append(msg); self)
  
  prepareData := method(
    data := "[" .. (self queue join(",")) .. "]"
    self queue removeAll
    data)
  
  close := method(
    log debug("Closed FutureResponse '#{self name}'")
    self closeSocket
    Generys futureResponses removeAt(self name))
  
  closeSocket := method(
    self socket ?_close; self socket ?close
    self socket = nil
    self)
  
  flush := method(
    if(self ?socket isOpen,
      self socket write(self prepareData); true,
      false
    ))
  
  finish := method(self flush ifTrue(self closeSocket))
)
