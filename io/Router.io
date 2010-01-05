Regex

Router := Object clone do (
//metadoc Router category Networking
/*metadoc Router description
Router. 
*/
  
  //doc Router connect(pattern) Creates Route with <code>pattern</code> and returns RouteMatch.
  connect := method(pattern, RouteMatch with(pattern))
  //doc Router resource(name) Returns RouteMatch.
  resource := method(name, ResourceMatch with(name))
  
  //doc Router GET(pattern) Creates Route which will only respond to HTTP GET. Returns RouteMatch.
  GET     := method(pattern, self connect(pattern) ifHttpMethod("GET"))
  //doc Router POST(pattern) Creates Route which will only respond to HTTP POST. Returns RouteMatch.
  POST    := method(pattern, self connect(pattern) ifHttpMethod("POST"))
  //doc Router PUT(pattern) Creates Route which will only respond to HTTP PUT. Returns RouteMatch
  PUT     := method(pattern, self connect(pattern) ifHttpMethod("PUT"))
  //doc Router DELETE(pattern) Creates Route which will only respond to HTTP DELETE. Returns RouteMatch.
  DELETE  := method(pattern, self connect(pattern) ifHttpMethod("DELETE"))

  //doc Router defaultRoutes() Assings default routes which enables acces to all controllers and their actions.
  defaultRoutes := method(
    self connect("/:controller/:action/:id.:format") to({controller: "#{controller}", action: "#{action}"})
    self connect("/:controller/:action/:id")         to({controller: "#{controller}", action: "#{action}"})
    self connect("/:controller/:action")             to({controller: "#{controller}", action: "#{action}"})
    self connect("/:controller")                     to({controller: "#{controller}", action: "index"}))

  /*doc Router fileServerRoutes()
  Assings route wich will check if a file exists in <code>Generys staticDir</code> which matches request path.
  If such file exits it will be served to the client.
  Note: this method has to be called explicitly in <code>routes.io</code> as a last route.
  */
  fileServerRoutes := method(
    self connect("*path") to(method(path, request, response,
      path = URL unescapeString(path)
      file := File with(Generys staticDir .. path)
      if(file exists, file, Exception raise("skipRoute"))
    )) as("fileServer"))
)
Router clone := Router

RouteMatch := Object do (
//metadoc RouteMatch category Networking
/*metadoc RouteMatch description
RouteMatch is the object with which you operate in routes.io. It provides methods for easier Route managment.
*/
  route ::= nil

  //metadoc RouteMatch with(pattern) Returns RouteMatch and assigns newly created Route.
  with := method(pattern, self clone setRoute(Route with(pattern)))

  /*metadoc RouteMatch to(options)
  Binds pattern with controller.
  <code>options</code> can be an Method or a Map with <code>controller</code> and <code>action</code> properties.
  
  Example:
  <pre><code>
  Router do(
    connect("/cars/new") to({controller: "Cars", action: "new"})
    connect("_:slot") to({controller: "Debug", action: "#{slot}"})
    connect("/time") to(method(request, response, Date now asString))

    connect("/") to({controller: "StaticPages"}) # action: index
  )</code></pre>*/
  to := method(
    if(call argAt(0) name == "method",
      route responseMethod := call evalArgAt(0),
      call evalArgAt(0) foreach(k, v, route setSlot(k, v)))
    self)
  //metadoc RouteMatch from() Same as <code>RouteMatch to</code>
  from := getSlot("to")

  /*metadoc RouteMatch ifHttpMethod() 
  Route will respond only to given HTTP verbs. You can provide more than one HTTP verb (uppercased).
  ex.:
  <pre><code>
  Router connect("/sessions/delete") ifHttpMethod("DELETE", "POST")</code></pre>*/
  ifHttpMethod := method(
    route setHttpMethods(call message arguments)
    self)

  /*metadoc RouteMatch as(name)
  Gives name to assinged route.
  This name can be later used from controller for redirections or generating links:
  
  router.io:
  <pre><code>
  Router do(
    connect("/sessions/create") as("login")
    # ...
  )</code></pre>

  Controller:
  <pre><code>
  authFailure := method(
    self isLoggedIn ifFalse(
      self redirectToRoute("login")
    )
    #...
  )</code></pre>*/
  as := method(name, route setName(name); self)
)

ResourceMatch := Object clone do(
//metadoc ResourceMatch category Networking
/*metadoc ResourceMatch description
<p>
ResourceMatch is object which is returned by <code>Router resource()</code> and you'll be mostly woking with it in <code>router.io</code>.
It provides convience methods for creating Routes which will automatically bind your controller's methods on a RESTful way.
</p>
<p>Routeing table for <code>Router resource("IceCream")</code>:</p>
<table>
  <thead>
    <tr>
      <th>Pattern</th>
      <th>HTTP verb</th>
      <th>Controller slot</th>
      <th>Route name</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>/<u>icecream</u>s</td>
      <td>GET</td>
      <td>index</td>
      <td>list<u>IceCream</u>s</td>
    </tr>
    <tr>
      <td>/<u>icecream</u>s/new</td>
      <td>GET</td>
      <td>new</td>
      <td>new<u>IceCream</u></td>
    </tr>
    <tr>
      <td>/<u>icecream</u>s</td>
      <td>POST</td>
      <td>create</td>
      <td>create<u>IceCream</u></td>
    </tr>
    <tr>
      <td>/<u>icecream</u>s/:id</td>
      <td>GET</td>
      <td>show</td>
      <td>show<u>IceCream</u></td>
    </tr>
    <tr>
      <td>/<u>icecream</u>s/:id</td>
      <td>PUT</td>
      <td>update</td>
      <td>update<u>IceCream</u></td>
    </tr>
    <tr>
      <td>/<u>icecream</u>s/:id</td>
      <td>DELETE</td>
      <td>destroy</td>
      <td>destroy<u>IceCream</u></td>
    </tr>
  </tbody>
</table>
<p>
Example:<br/>
router.io:
<pre><code>
  Router do(
    resource("Car") hasMany("Owners")
  )</code></pre>
</p>
<p>CarsController.io:
<pre><code>
CarsController := Controller clone do(
  index := method(Cars all)
  
  new := method(
    self view("app/views/car/new.html"))
  
  create := method(data,
    car := Car create(data)
    self redirectToRoute("showCar", {id: car id}))

  show := method(id,
    car := Car[id]
    self view("app/views/car/car.html") do(
      find("#car_name") setText(car["name"])
      find("#car_mph")  setText(car["mph"])
    ))
  
  update := method(id, data,
    car := Car[id]
    car union(data)
    car save

    self show(id))

  destory := method(id,
    Car removeAt(id)
    self redirectToRoute("listCar"))
)
</code></pre></p>*/

  name           ::= nil
  controllerPath ::= nil
  resourcePath   ::= nil

  //doc ResourceMatch with(resourceName)
  with := method(name,
    self cloneWithoutInit setName(name) init)

  init := method(
    self controllerPath = ("/" .. (self name) .. "s") asLowercase
    self resourcePath =  ("/" .. (self name) .. "/:id") asLowercase
    if(self name containsSeq("/"),
      _name := self name split("/") map(makeFirstCharacterUppercase)
      nameSingular := _name first
      self name = _name join("") .. "s"
    ,
      nameSingular := name
      self name = name .. "s"
    )
    
    Router GET(controllerPath)\
      from({controller: self name,   action: "index"})\
      as("list" .. name)
    Router GET(controllerPath .. "/new")\
      from({controller: self name,   action: "new"})\
      as("new" .. nameSingular)
    Router POST(controllerPath)\
      to({controller: self name, action: "create"})\
      as("create" .. nameSingular)
    Router GET(resourcePath)\
      from({controller: self name, action: "show"})\
      as("show" .. nameSingular)
    Router PUT(resourcePath)\
      to({controller: self name, action: "update"})\
      as("update" .. nameSingular)
    Router DELETE(resourcePath)\
      from({controller: self name, action: "destroy"})\
      as("destroy" .. nameSingular)
    
    self)

  /*doc ResourceMatch connectToSource(pattern, slotName)
  Creates route for other controller's slots. Returns self.
  These slots will be available on <code>/#{resourceName}/#{pattern}</code>
  */
  connectToSource := method(pattern, slotName,
    Router connect(self controllerPath .. "/" .. pattern) to({controller: self name, action: slotName})
    self)

  /*doc ResourceMatch allowSlotsOnResource(pattern, slotName)
  Creates routes for defined controller's slots. Returns self.
  These slots will be available on <code>/#{resourceName}s/:id/#{pattern}</code> 
  */
  connectToResource := method(pattern, slotName,
    Router connect(self resourcePath .. "/" .. pattern) to({controller: self name, action: slotName})
    self)

  //doc ResourceMatch hasOne() <strong>Not implemented!</strong> Returns <code>self</code>.
  hasOne := method(resourceName, self)
  //doc ResourceMatch hasMany(resourceName)
  hasMany := method(resourceName,
    ResourceMatch with(self name .. "/" .. resourceName); self)
)

Route := Object clone do(
//metadoc Route category Networking
/*metadoc Route description
Route is the core object of the whole routeing system within Generys,
but the end-user should never directly use it
(wrappers <code>RouteMatch</code> and <code>ResourceMatch</code> should be used instead).
*/
  name            ::= nil
  pattern         ::= nil
  controller      ::= "Application"
  action          ::= "index"
  responseMethod  ::= nil
  httpMethods     ::= ["GET", "POST", "PUT", "DELETE"]

  //doc Route with(pattern) Creates a new route and appends it to <code>Generys routes</code> list. 
  with := method(p, self clone setPattern(pattern))
  init := method(Generys routes append(self); self)

  /*doc Route patternMatches
  Extracts <code>:keyword</code> from patterns. Returns RegexMatches object.
  
  Example:
  <pre><code>
  Io> r := Route with("/:resource/ *path")
  Io> r patternMatches all map(string)
  ==> list(":resource", "*path")</code></pre>*/
  patternMatches := lazySlot(pattern matchesOfRegex("[:|\\*](\\w)+"))

  /*doc Route namedCaptures
  Removes ":" and "*" from strings returned by <code>Route patternMatches</code>. Returns List.*/
  namedCaptures := method(
    pattern ifNil(return [])
    self namedCaptures = self patternMatches map(part,
      if(part hasSlot("at"), part at(0) exSlice(1))))

  /*doc Route mapToPath(path)
  Maps <code>Route namedCaptures</code> to values from real path. Returns Map.
  <br/>
  Example:
  <pre><code>
  Io> r mapToPath("/chocolate/swiss/dark") asJson
  ==> {"resource": "chocolate", "path": "swiss/dark"}</code></pre>*/
  mapToPath := method(path,
    values := path allMatchesOfRegex(self asRegex)
    if(values isKindOf(List) and (values size > 0),
      values = values[0] ?captures ?exSlice(1),
      values = [])

    Map clone addKeysAndValues(self namedCaptures, values))

  //doc Route respondsTo(path, httpMethod) Returns <code>true</code> if path matches defined pattern. Otherwise, <code>false</code>.
  respondsTo := method(path, httpMethod,
    if(httpMethod, self httpMethods contains(httpMethod) ifFalse(return(false)))
    captures := self mapToPath(path)

    # Do not ask what this does
    # It's an uber smart algorithm for calculating meaning of life, universe and everything
    (path == self pattern)\
      or((captures values remove(nil) size > 0)\
        and(captures keys sort == self namedCaptures sort)))

  //doc Route asRegex Returns RegEx which can be tested agains paths.
  asRegex := method(
    self pattern ifNil(return nil)

    replaceRegex := if(self pattern contains("*"[0]), "([^\\?:]*)", "([^/\\?:]*)")
    re := self patternMatches replaceAllWith(replaceRegex)
    re = if(re exSlice(-1) == "/", re .. "?", re .. "/?") asRegex
    
    self asRegex = re)

  /*doc Route interpolate(context)
  Interpolate route's pattern. <code>context</code> can be either Map, either Object.
  <br/><br/>
  Example:
  <pre><code>
  Io> r interpolate({resource: "iceCream", path: "ledo/strawberry"})
  ==> "/iceCream/ledo/strawberry"</code></pre>*/
  interpolate := method(context,
    self pattern ifNil(return "")

    context ifNil(context = call sender)
    context isKindOf(Map) ifTrue(context = context asObject)

    seq := pattern clone asMutable
    self namedCaptures foreach(part,
      seq replaceSeq(":" .. part, context perform(part)))

    seq)
)
