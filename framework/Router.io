Regex

Router := Object clone do (
  match := method(pattern, RouteMatch clone setRoute(Route clone setPattern(pattern)))
  
  defaultRoutes := method(
    match("/:controller/:action/:id") to(controller := ":controller", action := ":action")
    match("/:controller/:action") to(controller := ":controller", action := ":action")
    match("/:controller") to(controller := ":controller", action := "index")
  )
  
  fileServerRoutes := method(
    match("*path") to(method(path, request, response,
      path = URL unescapeString(path)
      file := File clone setPath(Generys publicDir .. path)
      if(file exists and(file isDirectory not), file, Controller SKIP_ME)
    )) as("fileServer")
  )
)
Router clone := Router

RouteMatch := Object do (
  route ::= nil

  to := method(
    if(call argAt(0) name == "method",
      route responseMethod := call evalArgAt(0),
      call message arguments foreach(arg, route doMessage(arg))
    )
    self
  )
  as := method(name, route name := name; self)
)

Route := Object clone do(
  name            ::= nil
  pattern         ::= nil
  controller      ::= nil
  action          ::= nil
  responseMethod  ::= nil

  init := method(Generys routes append(self); self)

  # Extracts ":something" from pattern (eg. "/admin/:section/:id") as RegexMatch
  patternMatches := method(pattern matchesOfRegex("[:|\\*](\\w)+"))

  # Removes ":" from results of patterMatches, "section" and "id" in previous comment
  namedParts := method(patternMatches map(part,
    if(part hasSlot("at"), part at(0) exSlice(1))
  ))

  # Maps namedParts to values from real path (ex. "/admin/prefs/2")
  # section:="about", id:="2"
  mapToPath := method(path,
    values := path allMatchesOfRegex(asRegex)
    if(values hasSlot("at") and (values size > 0),
      values = values at(0) ?captures ?exSlice(1),
      values = List clone
    )
    Map clone addKeysAndValues(namedParts, values)
  )

  asRegex := method(
    # "*" at(0) == 42
    if(pattern contains(42), 
      replaceRegex := "([^\\?:]*)",
      replaceRegex := "([^/\\?:]*)"
    )
    pattern := patternMatches replaceAllWith(replaceRegex)
    if(pattern size == 1, return pattern asRegex)
    if(pattern exSlice(-1) == "/", "#{pattern}?", "#{pattern}/?") interpolate asRegex
  )
)
