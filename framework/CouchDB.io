URL
Yajl

Yajl ifNil(
  Yajl := Object clone do(
    parseJson := method(str, JsonParser parseJson(str))))

CouchDB := Object clone do(
  url ::= "http://127.0.0.1:5984/"
  
  with := method(server, dbName, 
    self clone setUrl(server .. ":" .. (port asString) .. "/" .. dbName .. "/"))
    
  at := method(path, options,
    (path[0] == "/"[0]) ifTrue(path = path exSlice(1))
    if(options isNil,
      options = "",
      options = "?" .. options )
    
    response := URL with(self url .. path) fetch
    Yajl parseJson(response))
  
  atPut := method(id, doc,
    if((doc isNil) and (id isKindOf(Map)), 
      doc = id
      id = doc["_id"])
    
    req := URL with(self url)
    if(id isNil,
      req := URL with(self url)
      req := URL with(self url .. id))
    resp := Yajl parseJson(req post(doc asJson))
    
    ((req statusCode == 200) or(req statusCode == 201)) ifTrue(
      doc atPut("_id", resp["id"])
      doc atPut("_rev", resp["rev"])))
)

CouchDBDocument := Map clone do(
  server ::= nil
  
  forward := method(self at(thisMessage name))
)