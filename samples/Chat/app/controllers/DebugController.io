DebugController := Controller clone do(
  beforeFilter("dontCache")
  
  index := method(self slotNames)

  controllers := method(
    Generys controllers map(c, "<pre>" .. c .. "</pre>") join)

  routes := method(
    Generys routes map(r, "<pre>" .. r .. "</pre>") join)

  formatters := method(
    Generys formatters map(f, "<pre>" .. f .. "</pre>") join)

  time := method(
    "<pre>" .. (Date now asString) .. "</pre>")
  
  currentSession := method("<pre>" .. session .. "</pre>")
  
  sessions := method(
    Generys sessions map(k, s, "<pre>" .. s slotSummary .. "</pre>") join("<hr/>"))
  
  futureResponses := method(
    Generys futureResponses keys map(k, "<pre>" .. k .. "</pre>") join)
)