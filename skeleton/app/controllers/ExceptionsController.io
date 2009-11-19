Generys ExceptionsController do(
  notFound := method(e,
    statusCode(404)
    "<h1>Not found (e#404)</h1>")
  noSlot := getSlot("notFound")
  noRoute := getSlot("notFound")

  internalError := method(e,
    setStatusCode(500)
    "<h1>Internal server error (e#500)</h1>")
  wrongRequestMethod := getSlot("internalError")
)