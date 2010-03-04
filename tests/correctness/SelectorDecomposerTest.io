SelectorDecomposerTest := UnitTest clone do(
  setUp := method()

  testSplit := method(
    assertEquals(SelectorDecomposer split("body #header .icon[alt=hi]"), list("body", "#header", ".icon[alt=hi]"))
    assertEquals(SelectorDecomposer split("el.icon[title=#123]") size, 1))

  testDecompose := method(
    tag               := SelectorDecomposer decompose("div")
    tagAndId          := SelectorDecomposer decompose("span#title")
    className         := SelectorDecomposer decompose(".icon")
    tagAndClassNames  := SelectorDecomposer decompose("img.icon.left")
    tagAndAttr        := SelectorDecomposer decompose("img[alt=Hai]")
    dotInAttr         := SelectorDecomposer decompose("abbr[alt=.today.]")
    sharpInAttr       := SelectorDecomposer decompose("a[title=p#120]")
    tagAndQuotedAttr  := SelectorDecomposer decompose("abbr[class='date right']")
    tagAndAttrs       := SelectorDecomposer decompose("img[width=16][height=\"32\"]")
    all               := SelectorDecomposer decompose("body#frontpage.mobile.landscape[height=320][alt=#12.23]")

    assertEquals(tag["tag"],                   "div")
    
    assertEquals(tagAndId["tag"],              "span")
    assertEquals(tagAndId["id"],               "title")
    
    assertEquals(className["classes"],         list("icon"))
    
    assertEquals(tagAndClassNames["tag"],      "img")
    assertTrue(tagAndClassNames["classes"] containsAll(list("icon", "left")))
    
    assertEquals(tagAndAttr["tag"],                       "img")
    assertEquals(tagAndAttr["attributes"]["alt"],         "Hai")
    
    assertEquals(dotInAttr["tag"],                        "abbr")
    assertEquals(dotInAttr["classes"],                    list())
    assertEquals(dotInAttr["attributes"]["alt"],          ".today.")
    
    assertEquals(sharpInAttr["tag"],                        "a")
    assertEquals(sharpInAttr["id"],                         nil)
    assertEquals(sharpInAttr["attributes"]["title"],        "p#120")

    assertEquals(tagAndQuotedAttr["tag"],                 "abbr")
    assertEquals(tagAndQuotedAttr["attributes"]["class"], "date right")
    
    assertEquals(tagAndAttrs["tag"],                      "img")
    assertEquals(tagAndAttrs["attributes"]["width"],      "16")
    assertEquals(tagAndAttrs["attributes"]["height"],     "32")
    
    assertEquals(all["tag"],                              "body")
    assertEquals(all["id"],                               "frontpage")
    assertTrue(all["classes"] containsAll(list("mobile", "landscape")))
    assertEquals(all["attributes"]["height"],             "320")
    assertEquals(all["attributes"]["alt"],                "#12.23"))
)