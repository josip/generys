log := Object clone do(
  symbols := {debug: "#", info: "-", error: "!"}
  
  print := method(seq, level,
   self write(" #{symbols[level]} [#{Date now}] #{seq}" interpolate println))
  
  write := method(msg, msg)
    #logFile := Generys config logFile
    #logFile ifNil(
    #  self write = method()
    #  return false)
    
    #(logFile type == "Sequence") ifTrue(logFile = File openForAppending(logFile))
    
    #self write = method(msg, Generys logFile appendToContents(msg); nil)
    #self write(msg)
    #)
  
  info  := method(seq, self @print(seq interpolate(call sender), "info"))
  error := method(seq, self @print(seq interpolate(call sender), "error"))
  debug := method(seq, self @print(seq interpolate(call sender), "debug"))
)
log clone = log
Log := log