Log := Object clone do(
//metadoc Log description Logging utility
  symbols := list(
    list("debug", "#"),
    list("info",  "-"),
    list("error", "!"))

  //doc Log print(message, logLevel)
  _logLevel := symbols map(at(0) == Generys config logLevel) indexOf(true)
  print := method(seq, level,
    msg := " #{symbols[level][1]} [#{Date now}] #{seq}" interpolate
    (level <= self _logLevel) ifTrue(
      msg println)
    self write(msg))

  if(Generys config logFile isNil,
    write := method()
  ,
    _logFile := File openForAppending(Generys config logFile)
    write := method(msg,
      self _logFile appendToContents(msg))
  )

  //doc Log debug(message) Prints debug message.
  debug := method(seq, self @print(seq interpolate(call sender), 0))
  //doc Log info(message) Prints info message.
  info  := method(seq, self @print(seq interpolate(call sender), 1))
  //doc Log error(message) Prints error message.
  error := method(seq, self @print(seq interpolate(call sender), 2))
)
log := Log
