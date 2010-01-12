SequenceTest := UnitTest clone do(
  testSquareBrackets := method(
    assertEquals("Strawberry"[0] asCharacter, "S")
    assertEquals("Mango"[3,5], "go"))
)
