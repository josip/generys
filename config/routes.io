Router do (
  # Take a peek into framework/Router.io
  # to understand some of the black magick show below
  GET("/_:action") from({controller: "Debug", action: ":action"})
  GET("/") from({controller: "StaticPages"})
  GET("/user/:id") from({controller: "Users", action: "show"})

  resource("User")

  fileServerRoutes
)
