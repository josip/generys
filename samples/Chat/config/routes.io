Router do (
  # Take a peek into Router.io to understand some of the black magick
  # which is manifested below
  
  connect("/_:action")     to({controller: "Debug", action: "#{action}"})
  
  connect("/chat")          to({controller: "Chat", action: "index"})
  connect("/chat/register") to({controller: "Chat", action: "register"})  as("register")
  connect("/chat/login")    to({controller: "Chat", action: "login"})     as("login")
  connect("/chat/logout")   to({controller: "Chat", action: "logout"})    as("logout")
  connect("/chat/post")     to({controller: "Chat", action: "post"})
  connect("/chat/updates")  to({controller: "Chat", action: "updates"})
  
  connect("/")              to({controller: "StaticPages"})
  fileServerRoutes
)