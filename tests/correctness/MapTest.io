MapTest := UnitTest clone do(
  testSquareBrackets := method(
    cc := {hr: "Croatia", uk: "United Kingdom", cy: "Cyprus", us: "United States of America"}
    
    assertEquals(cc["hr"], "Croatia")
    assertEquals(cc["cy"], "Cyprus")
    assertTrue(cc["uk", "us"] values containsAll(["United Kingdom", "United States of America"])))
)
