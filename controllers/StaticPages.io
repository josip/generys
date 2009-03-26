StaticPages := Controller clone do (
  name = "StaticPages"

  index := method(File clone setPath(Generys publicDir .. "/welcome.html"))
)