UsersController := Controller clone do(
  _users := [
    {name: "John", last_name: "Doe", password: "1245"},
    {name: "Jane", last_name: "Doe"}
  ]
  
  index := method(_users)

  show := method(id,
    user := _users[id asNumber]
    if(params["val"],
      user[params["val"]],
      user))
)