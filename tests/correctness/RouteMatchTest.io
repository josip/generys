RouteMatchTest := UnitTest clone do(
  setUp = method(
    self route := RouteMatch with("/:month/:day/:hour")\
      ifHttpMethods("GET", "POST")\
      to({controller: "Time", action: "show"})\
      as("time") route)
 
  testAdditionToGenerysRoutesList := method(
    assertTrue(Generys routes map(name) contains("time")))

  testRoutePattern := method(
    assertEquals(self route pattern, "/:month/:day/:hour"))
    
  testRouteDestination := method(
    assertEquals(self route controller, "Time")
    assertEquals(self route action,     "show")
    assertEquals(self route responseMethod, nil)
    assertTrue(self route respondsTo("/Jan/12/12",  "POST"))
    assertFalse(self route respondsTo("/Jan/12/04", "DELETE")))
)
