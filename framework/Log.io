log := Object clone do(
  symbols := {debug: "#", info: "-", error: "!"}
  
  logMessage := method(seq, level,
   " #{symbols[level]} #{seq}" interpolate println)
  
  info  := method(seq, logMessage(seq interpolate(call sender), "info"))
  error := method(seq, logMessage(seq interpolate(call sender), "error"))
  debug := method(seq, logMessage(seq interpolate(call sender), "debug"))
)
log clone = log
Log := log
