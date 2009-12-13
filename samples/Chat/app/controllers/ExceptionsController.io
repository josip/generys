Generys ExceptionsController do(
  notFound := method(e,
    setStatusCode(404)
    "<h1>Not found (e#404)</h1>")
  noSlot := getSlot("notFound")
  noRoute := getSlot("notFound")

  internalError := method(e,
    setStatusCode(500)
    "<h1>Internal server error (e#500)</h1>")
  wrongRequestMethod := getSlot("internalError")

  authRequired := method(
    session returnTo := request path
    redirectToRoute("login"))

  authFailure := method(
    view("static/chat/login.html") do(
      findFirst("form")\
        insertAfter("""<div class="error">Please check your email & password.</div>""")
    ))
)