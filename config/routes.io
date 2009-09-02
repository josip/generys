Router do (
  # match("/Users/:id") to(controller := "Users", action := "show")
  GET("/_:action") from({controller: "Debug", action: ":action"})
  GET("/") from({controller: "StaticPages"})
  GET("/user/:id") from({controller: "Users", action: "show"})

  resource("User")
  #GET("/users") from({controller: "Users", action: "index"})

  /*  GET("/favicon.ico") from(method(response,
    response contentType = "image/png"
    File clone setPath(Generys publicDir .. "/favicon.png")))
*/
  # See framework/Router.io
  fileServerRoutes
  #defaultRoutes
)
