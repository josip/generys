ListTest := UnitTest clone do(
  testSquareBrackets := method(
    colours := ["Green", "Blue", "Violet sky"]
    
    assertEquals(colours[0], "Green")
    assertEquals(colours[2], "Violet sky")
    assertEquals(colours[1,3], ["Blue", "Violet sky"]))
)
