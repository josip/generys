Regex

Router := Object clone do (
  connect := method(pattern, RouteMatch clone setRoute(Route clone setPattern(pattern)))
  
  GET     := method(self connect(call evalArgAt(0)) ifHttpMethod("GET"))
  POST    := method(self connect(call evalArgAt(0)) ifHttpMethod("POST"))
  PUT     := method(self connect(call evalArgAt(0)) ifHttpMethod("PUT"))
  DELETE  := method(self connect(call evalArgAt(0)) ifHttpMethod("DELETE"))

  resource := method(name, ResourceMatch cloneWithoutInit setName(name) init)

  defaultRoutes := method(
    connect("/:controller/:action/:id.:format") to({controller: ":controller", action: ":action"})
    connect("/:controller/:action/:id")         to({controller: ":controller", action: ":action"})
    connect("/:controller/:action")             to({controller: ":controller", action: ":action"})
    connect("/:controller")                     to({controller: ":controller", action: "index"}))

  fileServerRoutes := method(
    connect("*path") to(method(path, request, response,
      path = URL unescapeString(path)
      file := File with(Generys publicDir .. path)
      if(file exists, file, Exception raise("skipRoute"))
    )) as("fileServer"))
)
Router clone := Router

RouteMatch := Object do (
  route ::= nil

  to := method(
    if(call argAt(0) name == "method",
      route responseMethod := call evalArgAt(0),
      call evalArgAt(0) foreach(k, v, route setSlot(k, v)))
    self)
  from := method(call delegateToMethod(self, "to"))
  
  ifHttpMethod := method(
    route setHttpMethods(call message arguments)
    self)
  
  as := method(name, route setName(name); self)
)

ResourceMatch := Object clone do(
  name           ::= nil
  controllerPath ::= nil
  resourcePath   ::= nil
  
  init := method(resourceName,  
    controllerPath = ("/" .. name .. "s") asLowercase
    resourcePath =  ("/" .. name .. "/:id") asLowercase
    nameSingular := name
    name = name .. "s"
    
    Router GET(controllerPath)   from({controller: name,   action: "index"})    as("list" .. name)
    Router POST(controllerPath)  to({controller: name,     action: "create"})   as("create" .. nameSingular)
    Router GET(resourcePath)     from({controller: name,   action: "show"})     as("show" .. nameSingular)
    Router PUT(resourcePath)     to({controller: name,     action: "update"})   as("update" .. nameSingular)
    Router DELETE(resourcePath)  from({controller: name,   action: "destroy"})  as("destroy" .. nameSingular)
    
    self)

  hasOne := method(self)
  hasMany := method(self)
)

Route := Object clone do(
  name            ::= nil
  pattern         ::= nil
  controller      ::= "Application"
  action          ::= "index"
  responseMethod  ::= nil
  httpMethods     ::= {"GET", "POST", "PUT", "DELETE"}

  init := method(Generys routes append(self); self)

  # Extracts ":something" from pattern, ex.:
  # list(":section", ":id") from "/admin/:section/:id"
  patternMatches := method(
    self patternMatches = pattern matchesOfRegex("[:|\\*](\\w)+"))

  # Removes ":" from results of patterMatches, list("section" and "id") from previous comment
  namedCaptures := method(
    pattern ifNil(return list())
    self namedCaptures = patternMatches() map(part,
      if(part hasSlot("at"), part at(0) exSlice(1))))

  # Maps namedCaptures to values from real path (ex. "/admin/prefs/2")
  # mapToPath("/admin/prefs/2") => {section:"prefs", id:"2"}
  mapToPath := method(path,
    values := path allMatchesOfRegex(self asRegex)
    if(values isKindOf(List) and (values size > 0),
      values = values[0] ?captures ?exSlice(1),
      values = list())

    Map clone addKeysAndValues(self namedCaptures, values))

  respondsTo := method(path,
    captures := self mapToPath(path)
    
    path == self pattern or (captures values remove(nil) size > 0 and captures keys sort == self namedCaptures sort))

  asRegex := method(
    self pattern ifNil(return nil)
    
    replaceRegex := if(self pattern contains("*"[0]), "([^\\?:]*)", "([^/\\?:]*)")
    re := self patternMatches replaceAllWith(replaceRegex)
    re = if(re exSlice(-1) == "/", re .. "?", re .. "/?") asRegex
    
    self asRegex = re)

  interpolate := method(
    self pattern ifNil(return "")
    context := call evalArgAt(0)
    context isKindOf(Map) ifTrue(context = context asObject)
    context ifNil(context = call sender)
    
    seq = pattern clone
    self namedCaptures foreach(part,
      seq replace(":" .. part, context perform(part))))
)
