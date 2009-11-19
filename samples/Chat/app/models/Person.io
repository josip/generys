Person := CouchDocTemplate setup(  
  property("nick")
  property("email")
  property("password")
  property("logins")
  
  auth := method(email, password, self[email] auth(password))

  docProto do(
    auth := method(password,
      (self["password"] == password) ifFalse(return false)
      self["logins"] append(Date now)
      self)
  )
)
