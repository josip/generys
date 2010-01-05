log := Object clone do(
//metadoc log description Logging utility
  symbols := {debug: "#", info: "-", error: "!"}
  
  //doc log print(message, logLevel)
  print := method(seq, level,
   " #{symbols[level]} [#{Date now}] #{seq}" interpolate println)
  
  #write := method(msg, msg)
    #logFile := Generys config logFile
    #logFile ifNil(
    #  self write = method()
    #  return false)
    
    #(logFile type == "Sequence") ifTrue(logFile = File openForAppending(logFile))
    
    #self write = method(msg, Generys logFile appendToContents(msg); nil)
    #self write(msg)
    #)
  
  //doc log info(message) Prints info message.
  info  := method(seq, self @print(seq interpolate(call sender), "info"))
  //doc log error(message) Prints error message.
  error := method(seq, self @print(seq interpolate(call sender), "error"))
  //doc log debug(message) Prints debug message.
  debug := method(seq, self @print(seq interpolate(call sender), "debug"))
)
//doc log clone Returns <code>log</code> (singleton).
log clone = log
//metdoc Log description Alias for <code>log</code>.
Log := log