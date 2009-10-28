SessionsController := Controller clone do(
  beforeFilter("requireLogin", {except: {"index", "create"}})
  
  index := method()

  create := method(email, password,
    user := User find({email: email, password: password})
    user ifNil(Exception raise("internalError"))
    
    session atPut("currentUser", user))
  
  destroy := method()
)