ResourceMatchTest := UnitTest clone do(
  setUp := method(
    Generys routes = []
    self user := ResourceMatch with("User")
    self faves := user hasMany("Favourite"))
  
  testPaths := method(
    assertEquals(self user controllerPath,  "/users")
    assertEquals(self user resourcePath,    "/user/:id"))

  testRoutes := method(
    assertRoutesExist(
      "listUsers",  "newUser",    "createUser",
      "showUser",   "updateUser", "destroyUser")

    assertRouteAccepts(getRoute("listUsers"),   ["GET"])
    assertRouteAccepts(getRoute("newUser"),     ["GET"])
    assertRouteAccepts(getRoute("createUser"),  ["POST"])
    assertRouteAccepts(getRoute("showUser"),    ["GET"])
    assertRouteAccepts(getRoute("updateUser"),  ["PUT"])
    assertRouteAccepts(getRoute("destroyUser"), ["DELETE"]))

  testHasMany := method(
    assertRoutesExist(
      "listUsersFavourites",  "newUsersFavourite",    "createUsersFavourite",
      "showUsersFavourite",   "updateUsersFavourite", "destroyUsersFavourite")

    assertEquals(getRoute("listUsersFavourites") controller, "UsersFavourites"))

  testConnectToSource := method(
    favesCount := self faves connectToSource("count", "showFaveCount") as("countFavourites") route

    assertRouteExists("countFavourites")
    assertEquals(favesCount action, "showFaveCount")
    assertEquals(favesCount pattern, "/users/favourites/count"))

  testConnectToResource := method(
    sendFave := self faves connectToResource("send/:userId", "sendFave") as("sendFaveToUser") route

    #assertRouteExists("sendToUser")
    assertEquals(sendFave action, "sendFave")
    assertEquals(sendFave pattern, "/users/favourite/:id/send/:userId"))
)
