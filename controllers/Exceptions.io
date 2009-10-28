Generys ExceptionsController do(
  privateSlots = {"status"}

  notFound := method(e,
    self status(404)
    "<h1>Not found (e#404)</h1>")

  internalError := method(e,
    self status(500)
    "Internal server error (e#500)")

  wrongRequestMethod := getSlot("internalError")
  noRoute := method(call delegateToMethod(self, "notFound"))

  authRequired := method(
    session returnTo := request path
    redirectTo("/chat/login"))

  status := method(code, self response statusCode = code)
)