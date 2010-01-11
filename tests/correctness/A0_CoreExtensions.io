ObjectTest := UnitTest clone do(
  testSquareBrackets := method(
    assertEquals(["Keane", "Coldplay", "The Blue Nile"], list("Keane", "Coldplay", "The Blue Nile")))
  
  testCurlyBrackets := method(
    bandsAndAlbums := Map with(
      "Keane",          3,
      "Coldplay",       4,
      "MIKA",           2)
    
    assertEquals({Keane: 3, Coldplay: 4, MIKA: 2} values sort, bandsAndAlbums values sort))
  
  testAsMap := method(
    flavours := Object clone do(
      chocolate   := true
      vanilla     := true
      strawberry  := false
    )
    
    assertEquals(flavours asMap asJson, {chocolate: true, vanilla: true, strawberry: false} asJson))
)

ListTest := UnitTest clone do(
  testSquareBrackets := method(
    colours := ["Green", "Blue", "Violet sky"]
    
    assertEquals(colours[0], "Green")
    assertEquals(colours[2], "Violet sky")
    assertEquals(colours[1,3], ["Blue", "Violet sky"]))
)

MapTest := UnitTest clone do(
  testSquareBrackets := method(
    cc := {hr: "Croatia", uk: "United Kingdom", cy: "Cyprus", us: "United States of America"}
    
    assertEquals(cc["hr"], "Croatia")
    assertEquals(cc["cy"], "Cyprus")
    assertTrue(cc["uk", "us"] values containsAll(["United Kingdom", "United States of America"])))
)

SequenceTest := UnitTest clone do(
  testSquareBrackets := method(
    assertEquals("Strawberry"[0] asCharacter, "S")
    assertEquals("Mango"[3,5], "go"))
)