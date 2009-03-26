Controller clone do(
  name = "Debug"

  controllers := method(
    Generys controllers map(c, "<pre>" .. c .. "</pre>") join
  )

  routes := method(
    Generys routes map(r, "<pre>" .. r .. "</pre>") join
  )

  time := method(
    dontCache
    "<pre>" .. (Date now asString) .. "</pre>"
  )
)