DebugController := Controller clone do(
  index := method(self slotNames)

  controllers := method(
    Generys controllers map(c, "<pre>" .. c .. "</pre>") join)

  routes := method(
    Generys routes map(r, "<pre>" .. r .. "</pre>") join)

  formatters := method(
    Generys formatters map(f, "<pre>" .. f .. "</pre>") join)

  time := method(
    dontCache
    "<pre>" .. (Date now asString) .. "</pre>")
)