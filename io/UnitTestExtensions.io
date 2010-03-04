UnitTest do(
  getRoute := method(routeName,
    Generys routes select(name == routeName) first)

  assertRouteExists := method(routeName,
    assertNotNil(self getRoute(routeName)))

  assertRoutesExist := method(
    call evalArgs foreach(routeName, assertRouteExists(routeName)))

  assertRouteAccepts := method(route, httpVerbs,
    assertNotNil(route)
    assertEquals(route httpMethods, httpVerbs))
)
