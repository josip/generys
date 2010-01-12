RouteTest := UnitTest clone do(
  setUp = method(
    self car     := Route cloneWithoutInit setPattern("/cars/:carId")
    self music   := Route cloneWithoutInit setPattern("/:artist/:album/:song/play")
    self tasks   := Route cloneWithoutInit setPattern("/users/:userId/tasks/:taskId")
    self files   := Route cloneWithoutInit setPattern("/users/:userId/*path") setHttpMethods(["GET"])
    self empty   := Route cloneWithoutInit)

  #testPatternMatches := method(
  #  assertEquals(self car   patternMatches,   [":carId"])
  #  assertEquals(self tasks patternMatches, [":userId", ":taskId"])
  #  assertEquals(self files patternMatches, [":userId", "*path"])
  #  assertEquals(self empty patternMatches, []))

  testNamedCaptures := method(
    assertEquals(self car   namedCaptures,  ["carId"])
    assertEquals(self music namedCaptures,  ["artist", "album", "song"])
    assertEquals(self tasks namedCaptures,  ["userId", "taskId"])
    assertEquals(self files namedCaptures,  ["userId", "path"])
    assertEquals(self empty namedCaptures,  []))

  testMapToPath := method(
    carMapped   := self car mapToPath("/cars/12")
    extraCarMapped := self car mapToPath("/cars/tesla/roadster")
    musicMapped := self music mapToPath("/Keane/Hopes and Fears/Bedshaped/play")
    tasksMapped := self tasks mapToPath("/users/john/tasks/eleven")
    pathMapped  := self files mapToPath("/users/jane/home/.config")
    emptyMapped := self empty mapToPath("")

    assertEquals(carMapped["carId"], "12")
    assertTrue(extraCarMapped values isEmpty)

    assertEquals(musicMapped["artist"], "Keane")
    assertEquals(musicMapped["album"],  "Hopes and Fears")
    assertEquals(musicMapped["song"],   "Bedshaped")

    assertEquals(tasksMapped["userId"], "john")
    assertEquals(tasksMapped["taskId"], "eleven")

    assertEquals(pathMapped["userId"], "jane")
    assertEquals(pathMapped["path"], "home/.config")

    assertTrue(emptyMapped values isEmpty))
  
  testRespondsTo := method(
    assertTrue(self car respondsTo("/cars/volt"))
    assertFalse(self car respondsTo("/cars/yugo/45"))
    
    assertTrue(self music respondsTo("/Delphic/Acolyte/Counterpoint/play"))
    assertFalse(self music respondsTo("/Delphic/Hats/The Downtown Lights/download"))
    
    assertTrue(self files respondsTo("/users/mark/home/Music/Keane"))
    assertTrue(self files respondsTo("/users/mark/"))
    
    assertFalse(self empty respondsTo("/21/12/2012")))
  
  #testAsRegex := method()
  
  testInterpolate := method(
    userDetails := Object clone do(
      userId := "john"
      taskId := "42"
    )
    
    assertEquals(self car   interpolate({carId: 23}), "/cars/23")
    assertEquals(self tasks interpolate(userDetails), "/users/john/tasks/42")
    assertEquals(self files interpolate({userId: 42, path: "home/.creditcards"}), "/users/42/home/.creditcards")
    assertEquals(self empty interpolate(userDetails), ""))
)
