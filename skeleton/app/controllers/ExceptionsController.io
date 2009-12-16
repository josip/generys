Generys ExceptionsController do(
  noExceptionHandler := method(e,
    setStatusCode(500)

    if(Generys config env == "dev",
      "An unknown error occured:<br/><pre>#{e}</pre>" interpolate,
      "An unknown error occured."
    ))

  notFound := method(e,
    setStatusCode(404)
    "<h1>Not found (e#404)</h1>")
  noSlot := getSlot("notFound")
  noRoute := getSlot("notFound")

  internalError := method(e,
    setStatusCode(500)
    "<h1>Internal server error (e#500)</h1>")
  wrongRequestMethod := getSlot("internalError")
)