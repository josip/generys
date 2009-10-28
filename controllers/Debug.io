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
  
  currentSession := method("<pre>" .. session .. "</pre>")
  sessions := method(
    Generys sessions map(s, "<pre>" .. s .. "</pre>") join)
  
  futureResponses := method(
    Generys futureResponses keys map(k, "<pre>" .. k .. "</pre>") join)

  message := method(
    dontCache
    
    params["body"] ifNil(Exception raise("noMessage"))
    #(params["body"] == "**TIME**") ifTrue(params atPut("body", Date now asString))
    getFutureResponse("messages") push(params["body"]) finish
    
    return params["body"])

  messagePoll := method(createFutureResponse("messages"))
)