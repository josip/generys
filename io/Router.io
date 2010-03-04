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

  //doc Router defaultRoutes Assings default routes which enables acces to all controllers and their actions.
  defaultRoutes := method(
    self connect("/:controller/:action/:id.:format") to({controller: "#{controller}", action: "#{action}"})
    self connect("/:controller/:action/:id")         to({controller: "#{controller}", action: "#{action}"})
    self connect("/:controller/:action")             to({controller: "#{controller}", action: "#{action}"})
    self connect("/:controller")                     to({controller: "#{controller}", action: "index"}))

  /*doc Router fileServerRoutes
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

  //doc RouteMatch with(pattern) Returns RouteMatch and assigns newly created Route.
  with := method(pattern, self clone setRoute(Route with(pattern)))

  /*doc RouteMatch to(options)
  <p>Binds pattern with controller.
  <code>options</code> can be an Method or a Map with <code>controller</code> and <code>action</code> properties.
  </p><p>
  Example:
  <pre><code>
  Router do(
    connect("/cars/new") to({controller: "Cars", action: "new"})
    connect("_:slot") to({controller: "Debug", action: "#{slot}"})
    connect("/time") to(method(request, response, Date now asString))

    connect("/") to({controller: "StaticPages"}) # action: index
  )</code></pre></p>*/
  to := method(
    if(call argAt(0) name == "method",
      self route responseMethod := call evalArgAt(0),
      call evalArgAt(0) foreach(k, v, self route setSlot(k, v)))
    self)
  //metadoc RouteMatch from Same as <code>RouteMatch to</code>.
  from := getSlot("to")

  //doc RouteMatch ifHttpMethod(httpVerb) Same as <code>RouteMatch ifHttpMethods</code>.
  ifHttpMethod := method(verb,
    self route setHttpMethods(list(verb))
    self)
  
  /*doc RouteMatch ifHttpMethods(...) 
  Route will respond only to given HTTP verbs. You can provide more than one HTTP verb (all uppercased).
  Example:
  <pre><code>Router connect("/sessions/delete") ifHttpMethods("DELETE", "POST")</code></pre>*/
  ifHttpMethods := method(
    self route setHttpMethods(call evalArgs)
    self)

  /*doc RouteMatch as(name)
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
ResourceMatch is object which is returned by <code>Router resource</code> and you'll be mostly woking with it in <code>router.io</code>.
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
    car merege(data)
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
    self clone setName(name) setup)

  //doc ResourceMatch setup Installs resource methods.
  setup := method(
    self controllerPath = ("/" .. (self name) .. "s") asLowercase
    self resourcePath =  ("/" .. (self name) .. "/:id") asLowercase
    nameSingular := if(self name containsSeq("/"),
      self name split("/") map(makeFirstCharacterUppercase) join(""),
      name)
    self name = nameSingular .. "s"
    
    Router GET(self controllerPath)\
      from({controller: self name,   action: "index"})\
      as("list" .. name)
    Router GET(self controllerPath .. "/new")\
      from({controller: self name,   action: "new"})\
      as("new" .. nameSingular)
    Router POST(self controllerPath)\
      to({controller: self name, action: "create"})\
      as("create" .. nameSingular)
    Router GET(self resourcePath)\
      from({controller: self name, action: "show"})\
      as("show" .. nameSingular)
    Router PUT(self resourcePath)\
      to({controller: self name, action: "update"})\
      as("update" .. nameSingular)
    Router DELETE(self resourcePath)\
      from({controller: self name, action: "destroy"})\
      as("destroy" .. nameSingular)
    
    self)

  /*doc ResourceMatch connectToSource(pattern, slotName)
  Creates route for other controller's slots. Returns RouteMatch with newly created route.
  These slots will be available on <code>/#{resourceName}s/#{pattern}</code>
  */
  connectToSource := method(pattern, slotName,
    Router connect((self controllerPath) .. "/" .. pattern) to({controller: self name, action: slotName}))

  /*doc ResourceMatch allowSlotsOnResource(pattern, slotName)
  Creates routes for defined controller's slots. Returns RouteMatch with newly created route.
  These slots will be available on <code>/#{resourceName}/:id/#{pattern}</code> 
  */
  connectToResource := method(pattern, slotName,
    Router connect((self resourcePath) .. "/" .. pattern) to({controller: self name, action: slotName}))

  //doc ResourceMatch hasOne Not implemented. Returns <code>self</code>.
  hasOne := method(resourceName, self)
  
  //doc ResourceMatch hasMany(resourceName)
  hasMany := method(resourceName,
    (resourceName exSlice(-1) == "s") ifTrue(resourceName = resourceName exSlice(0, -1))
    ResourceMatch with((self name) .. "/" .. resourceName))
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
  with := method(p, self clone setPattern(p))
  init := method(Generys routes append(self); self)

  /*doc Route patternMatches
  Extracts <code>:keyword</code> from patterns. Returns RegexMatches object.
  
  Example:
  <pre><code>
  Io> r := Route with("/:resource/<!-- O.o-->*path")
  Io> r patternMatches all map(string)
  ==> list(":resource", "*path")</code></pre>*/
  patternMatches := lazySlot(pattern matchesOfRegex("[:|\\*](\\w)+"))

  /*doc Route namedCaptures
  Removes ":" and "*" from strings returned by <code>Route fullNamedCaptures</code>. Returns List.*/
  namedCaptures := method(
    pattern ifNil(return([]))
    self namedCaptures = self fullNamedCaptures map(exSlice(1)))

  //doc Route fullNamedCaptures Returns matches of URL pattern (with ":" or "*" at beginning) as List of Sequences.
  fullNamedCaptures := method(
    pattern ifNil(return([]))
    self fullNamedCaptures = self patternMatches map(part,
      if(part hasSlot("at"), part at(0), nil)) select(isNil not))

  /*doc Route mapToPath(path)
  Maps <code>Route namedCaptures</code> to values from real path. Returns Map.
  <br/>
  Example:
  <pre><code>
  Io> Route with("/:resource/<!-- o.O -->*path") mapToPath("/chocolate/swiss/dark") asJson
  ==> {"resource": "chocolate", "path": "swiss/dark"}</code></pre>*/
  mapToPath := method(path,
    self asRegex ifNil(return(Map clone))
    values := path allMatchesOfRegex(self asRegex) remove(nil)
    if(values isKindOf(List) and(values isEmpty not),
      Map clone addKeysAndValues(self namedCaptures, values[0] ?captures ?exSlice(1)),
      Map clone))

  //doc Route respondsTo(path, httpMethod) Returns <code>true</code> if path matches defined pattern. Otherwise, <code>false</code>.
  respondsTo := method(path, httpMethod,
    if(httpMethod, self httpMethods contains(httpMethod) ifFalse(return(false)))
    captures := self mapToPath(path)

    # Do not ask what this does
    # It's a uber smart algorithm for calculating meaning of life, universe and everything.
    (path == self pattern)\
      or((captures values remove(nil) size > 0)\
        and(captures keys sort == self namedCaptures sort)))

  //doc Route asRegex Returns RegEx which can be tested agains URLs.
  asRegex := method(
    self pattern ifNil(return(nil))

    re := self pattern clone asMutable
    self fullNamedCaptures foreach(match,
      re replaceSeq(match, if(match[0] asCharacter == "*", "([^\\?:]*)", "([^/\\?\\:]*)")))
    re = "^" .. re .. (if(re exSlice(-1) == "/", "?", "/?$"))

    self asRegex = re asRegex)

  /*doc Route interpolate(context)
  Interpolate route's pattern. <code>context</code> can be either Map, either Object.
  <br/><br/>
  Example:
  <pre><code>
  Io> r interpolate({resource: "iceCream", path: "ledo/strawberry"})
  ==> "/iceCream/ledo/strawberry"</code></pre>*/
  interpolate := method(context,
    self pattern ifNil(return(""))

    context ifNil(context = call sender)
    context isKindOf(Map) ifTrue(context = context asObject)

    seq := pattern clone asMutable
    self fullNamedCaptures foreach(match,
      seq replaceSeq(match, context perform(match exSlice(1)) asString))

    seq)
)
