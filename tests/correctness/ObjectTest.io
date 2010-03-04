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
    ) asMap
    
    assertTrue(flavours at("chocolate"))
    assertTrue(flavours at("vanilla"))
    assertFalse(flavours at("strawberry")))
)