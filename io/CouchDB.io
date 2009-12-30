URL
UUID
Yajl

CouchDB := Object clone do(
  url ::= "http://127.0.0.1:5984/"
  dbName ::= nil

  with := method(server, dbName, port,
    self dbName = dbName

    server ifNil(server = "localhost")
    port ifNil(port = 5984)
    self clone setUrl("http://" .. server .. ":" .. (port asString) .. "/" .. dbName .. "/"))

  at := method(path, options,
    (path[0] == "/"[0]) ifTrue(path = path exSlice(1))
    if(options isNil,
      options = "",
      options = "?" .. (options asQueryString))
    
    e := try(
      resp := URL with(self url .. path .. oprtions) fetch)
    e catch(
      CouchDbException clone setIsConnectError(true) raise)

    CouchDoc from(Yajl parseJson(resp)) setDb(self))
  squareBrackets := getSlot("at")

  atPut := method(id, doc,
    if((doc isNil) and (id isKindOf(Map)),
      doc = CouchDoc from(id) setDb(self)
      id = doc["_id"])
    
    id ifNil(
      id = UUID uuid
      doc atPut("_id", id))
    
    req := URL with(self url .. id)
    resp := req put(doc asJson)
    
    parseStatusCode(req statusCode, resp) ifTrue(
      resp = Yajl parseJson(resp)
      doc atPut("_id", resp["id"])
      doc atPut("_rev", resp["rev"])))
  
  create := method(
    req := URL with(self url)
    resp := req put
    
    parseStatusCode(req statusCode, resp) ifTrue(self))
  
  select := method(viewName, options,
    if(options isNil,
      options = "",
      options = "?" .. (options asQueryString))

    req := URL with(self url .. "_design/" .. (self .. dbName) .. "/" .. viewName .. options)
    resp := req fetch
    
    parseStatusCode(req statusCode, resp) ifTrue(
      resp = Yajl parseJson(resp)
      ))
  
  getView := getSlot("select")

  parseStatusCode := method(code, body,
    code switch(
      400, CouchDBException clone setIsBadRequest(true),
      404, CouchDBException clone setIsNotFound(true),
      405, CouchDBException clone setIsResourceNotAllowed(true),
      409, CouchDBException clone setIsConflict(true),
      412, CouchDBException clone setIsPreconditionFailed(true),
      500, CouchDBException clone setIsInternalServerError(true)) ?raise(body)
    true)
)

CouchDBException := Exception clone do(
  isBadRequest            ::= false
  isNotFound              ::= false
  isResourceNotAllowed    ::= false
  isConflict              ::= false
  isPreconditionFailed    ::= false
  isInternalServerError   ::= false)

CouchDoc := Map clone do(
  db ::= nil
  
  init := method(
    self radio := Radio clone)
  
  from := method(map, 
    if(map["ioType"] isNil or map["ioType"] == self type,
      self clone merge(map)
    ,
      docProto := Object getSlot(map["ioType"])
      
      docProto ifNil(
        map atPut("ioType", nil)
        return self from(map))
      
      if(docProto isKindOf(CouchDocTemplate),
        docProto docProto clone merge(map),
        docProto with(map))
    ))
  
  id := method(self["_id"])
  rev := method(self["_rev"])

  delete := method(
    id ifNil(Exception raise("Document is missing '_id' property, could not delete it"))
    rev ifNil(Exception raise("Document is missing '_rev' propery, could not delete it"))

    self radio emit("beforeDelete", self)
    req := URL with(self db url .. id .. "?rev=" .. rev)
    resp := req delete
    self db parseStatusCode(req statusCode) ifTrue(
      self isDeleted := true
      self radio emit("afterDelete")))

  update  := method(
    self radio emit("beforeUpdate", self)
    self db atPut(id, self)
    self radio emit("afterUpdate", self)
    self)
  save    := getSlot("update")

  create  := method(
    self radio emit("beforeCreate", self)
    self db atPut(self) ifTrue(
      self radioEmit("afterCreate", self))
    self)

  listenTo := method(channel, callback, self radio listenTo(channel, callback); self)
)

CouchDocTemplate := Object clone do(
  properties  ::= list()
  db          ::= nil
  docProto    ::= nil
  
  setup := method(
    self clone doMessage(call message setName("do")) done)

  init := method(
    self setDocProto(CouchDoc clone))

  done := method(
    self db ifNil(self db = CouchDB default)
    self docProto setDb(self db)
    # TODO: relations magic, etc.
    self)

  property := method(prop, self properties append(prop))
  
  timestamps := method(
    self property("created_at")
    self property("updated_at")
    self)

  before := method(event, callback,
    self docProto listenTo("before" .. (event makeFirstCharacterUppercase), callback)
    self)

  after := doString(getSlot("before") code asMutable replaceSeq("before", "after"))

  new := method(theProperties,
    doc := self docProto from(theProperties)
    doc atPut("ioType", self type)
    doc)
  
  create := method(theProperties,
    self new(theProperties) create)
  
  at := method(key, self docProto from(self db[key]))
  squareBrackets := method(key, self at(key))
)
