Log := Object clone do(
//metadoc Log description Logging utility
  symbols := [
    ["debug", "#"],
    ["info",  "-"],
    ["error", "!"]
  ]

  //doc log print(message, logLevel)
  _logLevel := symbols map(s, s at(0) == Generys config level) indexOf(true)
  _shouldPrint := Generys config shouldPrint
  print := method(seq, level,
    msg := " #{symbols[level][1]} [#{Date now}] #{seq}" interpolate
    if((level <= (self _logLevel)) and(self _shouldPrint),
      msg println)
    self write(msg))

  if(Generys config logFile isNil,
    write := method()
  ,
    _logFile := File openForAppending(Generys config logFile)
    write := method(msg,
      self _logFile appendToContents(msg))
  )

  //doc log debug(message) Prints debug message.
  debug := method(seq, self @print(seq interpolate(call sender), 0))
  //doc log info(message) Prints info message.
  info  := method(seq, self @print(seq interpolate(call sender), 1))
  //doc log error(message) Prints error message.
  error := method(seq, self @print(seq interpolate(call sender), 2))
)
log := log
