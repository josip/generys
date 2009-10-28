Generys futureResponses := Map clone
FutureResponse := Object clone do(  
  name        ::= nil
  socket      ::= nil
  body        ::= nil
  queue       ::= list()
  limit       ::= 1
  
  init := method(
    log debug("Created new FutureResponse")
    self queue = list(); self)

  push := method(msg, self queue push(msg); self)

  close := method(
    self closeSocket
    Generys futureResponses removeAt(self name))
  
  closeSocket := method(
    self socket ?_close
    self socket close
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

FutureResponse at := method(name, Generys futureResponses[name])