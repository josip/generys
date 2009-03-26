Router do (
  match("/Users/:id") to(controller := "Users", action := "show")
  match("/_:action") to(controller := "Debug", action := ":action")

  match("/") to(controller := "StaticPages")
  match("/favicon.ico") to(method(response,
    response contentType = "image/png"
    File clone setPath(Generys publicDir .. "/favicon.png")
  ))

  # See framework/Router.io
  fileServerRoutes
  defaultRoutes
)
