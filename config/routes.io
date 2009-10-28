Router do (
  # Take a peek into framework/Router.io
  # to understand some of the black magick show below
  resource("User") hasMany("comments", "messages") hasOne("profilePicture")
  
  GET("/_:action") from({controller: "Debug", action: ":action"})
  
  GET("/chat")        from({controller: "Chat", action: "index"})
  POST("/chat/login")   to({controller: "Chat", action: "login"})
  GET("/chat/logout") from({controller: "Chat", action: "logout"})
  POST("/chat/post")    to({controller: "Chat", action: "post"})
  POST("/chat/updates") to({controller: "Chat", action: "updates"})
  
  GET("/") from({controller: "StaticPages"})
  fileServerRoutes
)
