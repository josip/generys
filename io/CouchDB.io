URL
UUID
Yajl

CouchDB := Object clone do(
//metadoc CouchDB category networking
/*metadoc CouchDB description
A simple library for working with CouchDB.
<pre><code>
db := CouchDB with("localhost", "icecreams")
db create
db atPut("chocolate", {likes: 5, grade: 3, tags: ["favourite"], colours: ["brown"]})
choc := db["chocolate"]["grade"]
Io> choc type
==> CouchDoc
Io> choc["colours"]
==> list("brown")
Io> db["vanilla"]
==> nil
</code></pre> 
*/
  url ::= "http://127.0.0.1:5984/"
  dbName ::= nil

  //doc CouchDB witH(server, databaseName[, port]) Returns CouchDB object.
  with := method(server, dbName, port,
    server ifNil(server = "localhost")
    port ifNil(port = 5984)

    self clone setDbName(dbName) setUrl("http://#{server}:#{port}/#{dbName}/" interpolate))

  //doc CouchDB at(id[, options]) Access database documents. Returns CouchDoc.
  at := method(id, options,
    (id[0] == "/"[0]) ifTrue(id = id exSlice(1))
    if(options isNil,
      options = "",
      options = "?" .. (options asQueryString))
    
    e := try(
      resp := URL with((self url) .. id .. options) fetch)
    e catch(
      CouchDBException clone setIsConnectError(true) raise)

    CouchDoc from(Yajl parseJson(resp)) setDb(self))
  
  //doc CouchDB squareBrackets(id[, options]) Alias of <code>CouchDB at</code>.
  squareBrackets := getSlot("at")

  /*doc CouchDB atPut(id, document)
  Puts document into DB.
  You can either pass CouchDoc or Map as only argument,
  in that case unless it has <em>_id</em> property, unique ID will be generated. */
  atPut := method(id, doc,
    if((doc isNil) and(id isKindOf(Map)),
      doc = CouchDoc from(id) setDb(self)
      id = doc["_id"])
    
    id ifNil(
      id = UUID uuid
      doc atPut("_id", id))
    
    req := URL with(self url .. id)
    resp := req put(doc asJson)
    
    self parseStatusCode(req statusCode, resp) ifTrue(
      resp = Yajl parseJson(resp)
      doc atPut("_id", resp["id"])
      doc atPut("_rev", resp["rev"])))
  
  
  //doc CouchDB create Creates database.
  create := method(
    req := URL with(self url)
    resp := req put
    
    self parseStatusCode(req statusCode, resp) ifTrue(self))
  
  /*doc CouchDB select(viewName[, options])
  Access results of a view.<br/>
  <code>options</code> Map can contain HTTP query params which CouchDB supports.*/
  select := method(viewName, options,
    if(options isNil,
      options = "",
      options = "?" .. (options map(k, v, v asJson) asQueryString))

    viewName containsSeq("/") ifFalse(
      viewName = (self dbName) .. "/" .. viewName)
    req := URL with("#{self url}_design/#{self dbName}/#{viewName}#{options}" interpolate)
    resp := req fetch
    
    self parseStatusCode(req statusCode, resp) ifTrue(
      # We have to excplicitly return 'cos Io would return true otherwise.
      return(CouchDBView with(Yajl parseJson(resp), self))))
  
  //doc CouchDB getView(viewName[, options]) Alias of <code>CouchDB select</code>
  getView := getSlot("select")

  //doc CouchDB parseStatusCode(code, body) Parses status code and raises CouchDBException if needed.
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
//metadoc CouchDBException category Networking
  isBadRequest            ::= false
  isNotFound              ::= false
  isResourceNotAllowed    ::= false
  isConflict              ::= false
  isPreconditionFailed    ::= false
  isInternalServerError   ::= false
  isConnectError          ::= false
)

CouchDoc := Map clone do(
//metadoc CouchDoc category Networking
//metadoc CouchDoc description Map with extra methods for easier interaction with CouchDB
  db        ::= nil
  isDeleted ::= false
  
  init := method(
    self notifications := Object clone
    ["Create", "Update", "Delete", "Save"] foreach(notif,
      self notifications setSlot("before" .. notif,
        Notification clone setName("before" .. notif) setSender(self))
      
      self notifications setSlot("after" .. notif,
        Notification clone setName("after" .. notif) setSender(self))))

  //doc CouchDoc from(map) Converts Map to CoucDoc. 
  from := method(obj,
    obj ifNil(Exception raise("Trying to create CouchDoc from nil."))

    if(obj["ioType"] isNil or obj["ioType"] == self type,
      self clone merge(obj)
    ,
      docProto := Object getSlot(obj["ioType"] asString)

      docProto ifNil(
        obj atPut("ioType", nil)
        return(self from(obj)))
      
      if(docProto isKindOf(CouchDocTemplate),
        docProto docProto clone merge(obj),
        docProto with(obj))
    ))
  
  //doc CouchDoc id Returns value of <code>_id</code> property.
  id := method(self["_id"])
  //doc CouchDoc rev Returns value of <code>_rev</code> property.
  rev := method(self["_rev"])

  /*doc CouchDoc delete
  Deletes document from database.
  Emits <code>beforeDelete</code> and <code>afterDelete</code> events.*/
  delete := method(
    id ifNil(Exception raise("Document is missing '_id' property, could not delete it"))
    rev ifNil(Exception raise("Document is missing '_rev' propery, could not delete it"))

    self notifications beforeDelete post
    req := URL with(self db url .. id .. "?rev=" .. rev)
    resp := req delete
    self db parseStatusCode(req statusCode) ifTrue(
      self isDeleted = true
      self notifications afterDelete post))

  /*doc CouchDoc update
  Saves document to database.
  Emits <code>beforeUpdate</code> and <code>afterUpdate</code> events.*/
  update  := method(
    self notifications beforeUpdate post
    self db atPut(id, self) ifTrue(
      self notifications afterUpdate post)
    self)
  //doc CouchDoc save Alias of <code>CouchDoc update</code>.
  save    := getSlot("update")

  /*doc CouchDoc create
  Creates document in the database.
  Emits <code>beforeCreate</code> and <code>afterCreate</code> events.*/
  create  := method(
    self notifications beforeCreate post
    self db atPut(self) ifTrue(
      self notifications afterCreate post)
    self)

  /*doc CouchDoc listenTo(event, slotName[, target])
  Subscribes callback to an event on <code>self</code> instance.
  If <code>target</code> is provided, its slot <code>slotName</code> will be called.<br/>
  Returns <code>NotificationListener</code>.*/
  listenTo := method(event, slotName, target,
    target ifNil(target = self)
    NotificationListener clone\
      setTarget(target)\
      setSender(self)\
      setName(event)\
      setAction(slotName)\
      start)

  //doc CouchDoc before(event, slotName[, target]) Subscribe callback to an <em>before</em> event.
  before := method(event, slotName, target,
    self listenTo("before" .. (event makeFirstCharacterUppercase), slotName, target))

  //doc CouchDoc after(event, slotName[, target]) Subscribe callback to an <em>after</em> event.
  after := method(event, slotName, target,
    self listenTo("after" .. (event makeFirstCharacterUppercase), slotName, target))
)

# We can't clone Map because rows which view returns can have same keys.
CouchDBView := Object clone do(
  //doc CouchDBView db CouchDB object.
  db          ::= nil
  //doc CouchDBView totalSize View's total size
  totalSize   ::= nil
  offset      ::= nil
  //doc CouchDBView documentIds List of document ids to which rows belong.
  documentIds ::= nil
  rows        ::= nil

  with := method(response, db,
    _rows := response["rows"]
    self clone\
      setDb(db)\
      setTotalSize(response["total_rows"])\
      setOffset(response["offset"])\
      setDocumentIds(_rows map(["id"]))\
      setRows(_rows))

  //doc CouchDBView documents CouchDoc's of all result rows. 
  documents := lazySlot(
    self documentIds map(id, self db[id]))
  
  //doc CouchDBView documentAt(index) Returns CouchDoc with ID which is at n-th row. 
  documentAt := method(index,
    if(self getSlot("documents") isKindOf(List),
      self documents[index],
      self db[self documentIds[index]]))
  
  //doc CouchDBView at(index) Returns row at <code>index</code>.
  at := method(index,
    self rows at(index); self)
  //doc CouchDBView squareBrackets(index) Alias of <code>CouchDBViewResponse at</code>.
  squareBrackets := getSlot("at")

  //doc CouchDBView keys Returns list of all keys provided by view response.
  keys := method(self rows map(["key"]))
  
  //doc CouchDBView values Returns list of all values.
  values := method(self rows map(["value"]))
  
  //doc CouchDBView size Returns size rows returned by CouchDB.
  size := method(self rows size)
)

CouchDocTemplate := Object clone do(
//metadoc CouchDocTemplate category Networking
/*metadoc CouchDocTemplate description
CouchDocTemplate is a simple ORM for CouchDB documents.
<pre><code>
IceCream := CouchDocTemplate setup(
  property("name")
  property("flavours")
  property("colours")
  property("price")
  timestamps
  
  docProto do(
    before("create", method(doc,
      ("We've got new Ice Cream!" .. doc[name]) println))
    
    is := method(colour,
      self["colours"] contains(colour))
    
    shouldBe := method(colour,
      self["colours"] appendIfAbsent(colour); self)
  )
)

Io> chocolate := IceCream create({
  _id: "chocolate",
  name: "Chocolate",
  flavours: ["chocolate"],
  colours: ["brown"],
  price: 12.20})
We've got new ice cream! Chocolate!
==> IceCream_0xfeed4beed:
...
Io> chocolate id
==> "random-uuid-string-(for-real-,-not-kidding)"
Io> chocolate is("green")
==> false
Io> chocolate shouldBe("green")
==> IceCream_0xfeed4beef:
...
Io> chocolate save
Io> IceCream["chocolate"] == chocolate
</code></pre>
*/
  properties  ::= list()
  db          ::= nil
  //doc CouchDocTemplate docProt Slots added to his object will be available to all documents created from this template.
  docProto    ::= nil
  
  //doc CouchDocTemplate setup Use this method when defining CouchDocTemplate.
  setup := method(
    self clone doMessage(call message setName("do")) done)

  init := method(
    self setDocProto(CouchDoc clone))

  //doc CouchDocTemplate done If you're not using <code>CouchDocTemplate setup</code> make sure you call this method after you've defined CouchDocTemplate and all the properties.
  done := method(
    self db ifNil(self db = CouchDB default ifNil(Exception raise("No database defined")))
    self docProto setDb(self db)
    # TODO: relations magic, etc.
    self)

  //doc CouchDocTemplate property(propertyName) Adds property to template. No magic for now.
  property := method(prop, self properties append(prop))
  
  //doc CouchDocTemplate timestamps Adds <em>created_at</em> and <em>updated_at</em> properties, as well as listeners to template.
  timestamps := method(
    self property("created_at")
    self property("updated_at")
    
    self docProto do(
      before("create", method(self atPut("created_at", Date now)))
      before("update", method(self atPut("updated_at", Date now)))
    )

    self)

  //doc CouchDocTemplate new(properties) Creates new CouchDoc and sets <em>ioType</em> property.
  new := method(props,
    doc := self docProto from(props select(k, v, self properties contains(k)))
    #doc := self docProto from(theProperties)
    doc atPut("ioType", self type)
    doc)
  
  //doc CouchDocTemplate create(properties) Creates new CouchDoc and creates it in database.
  create := method(props,
    self new(props) create)
  
  //doc CouchDocTemplate at(id) Returns CouchDoc with <code>docProto</code> methods.
  at := method(id, self docProto from(self db[id]))
  
  //doc CouchDocTemplate squareBrackets(id) Alias for <code>CouchDocTemplate at</code>.
  squareBrackets := getSlot("at")
)
