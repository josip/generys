Generys 
SGMLElementTest := UnitTest clone do(
  setUp := method(
    self doc := """
    <html>
      <head>
        <title>Ice creams</title>
      </head>
      <body>
        <h1>Ice creams</h1>
        <h2>List of all ice cream flavours I could imagine at times moment</h2>
        <p>
          <ul id="iceCreamFlavours">
            <li class="firstInList">Chocolate</li>
            <li><a href="http://en.wikipedia.org/wiki/Vanilla">Vanilla</a></li>
            <li>Strawberry</li>
            <li>Lemon</li>
            <li>Punch</li>
            <li>Tiramisu</li>
            <li><a href="http://en.wikipedia.org/wiki/Banana">Banana</a></li>
            <li>Mars</li>
            <li>Nutella</li>
            <li class="lastInList">Pistacio</li>
          </ul>
        </p>
      </body>
    </html>
    """ asHTML)

  testIsMatchedBySelector := method(
    assertTrue(doc subitems[1] subitems[3] isMatchedBySelector("body"))
    assertTrue(doc subitems[1] subitems[3] subitems[1] isMatchedBySelector("h1")))

  testElementsBySelector := method(
    lis := doc subitems[1] subitems[3] subitems[5] subitems[1] subitems

    assertTrue(lis containsAll(doc elementsBySelector("li")))
    assertEquals(doc elementsBySelector("a") first, lis[3] subitems first))

  testFind := method(
    lis := doc subitems[1] subitems[3] subitems[5] subitems[1] subitems
    link := lis[3] subitems first

    assertTrue(lis containsAll(doc find("html body p ul li")))
    assertTrue(lis containsAll(doc find("html li")))
    assertTrue(lis containsAll(doc find("ul li")))
    assertEquals(doc find("a") first, link)
    assertEquals(doc find("li a") first, link)
    assertEquals(doc find("li.lastInList") first, lis detect(attribute("class") == "lastInList")))

  testAppend := method(
    doc findFirst("body") append("""<hr/><p>Hai</p>""")

    assertNotNil(doc findFirst("hr"))
    assertEquals(doc find("p") size, 2))
) run