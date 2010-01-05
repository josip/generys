ChatExceptionsController := ExceptionsController clone do(
  authRequired := method(
    self session returnTo := request path
    self redirectToRoute("login"))

  authFailure := lazySlot(
    view((Generys staticDir) .. "/chat/login.html") do(
      findFirst("form")\
        insertAfter("""<div class="error">Please check your email & password.</div>""")
    ))
)