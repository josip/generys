DebugController := Controller clone do(
  beforeFilter("dontCache")
  
  index := lazySlot(self slotNames)

  controllers := lazySlot(
    Generys controllers map(c, "<pre>" .. c .. "</pre>") join)

  routes := lazySlot(
    view("static/routes.html") do(
      thead := self findFirst("table thead")
      Generys routes foreach(r, thead append("<span>" .. r controller .. "</span>"))
    ))

  formatters := method(
    Generys formatters map(f, "<pre>" .. f .. "</pre>") join)

  time := method(
    "<pre>" .. (Date now asString) .. "</pre>")
  
  currentSession := method("<pre>" .. session .. "</pre>")
  
  sessions := method(
    Generys sessions map(k, s, "<pre>" .. s slotSummary .. "</pre>") join("<hr/>"))
  
  futureResponses := method(
    Generys futureResponses keys map(k, "<pre>" .. k .. "</pre>") join)
  
  webSockets := method(
    Generys webSockets map(k, v, "<pre>" .. v .. "</pre>") join)
  
  headers  := method("<pre>" .. (self request headers asObject) .. "</pre>")
)