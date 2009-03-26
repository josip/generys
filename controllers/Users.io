Controller clone do(
  _users := list(
    {name := "Josip", last_name := "Lisec"},
    {name := "Marko", last_name := "Lisec"}
  )

  index := method(_users)

  show := method(id,
    user := _users at(id asNumber)
    if(params hasSlot("val"), user at(params val), user)
  )
)