Regex

CSS := Object clone do(
  selectors ::= nil

  init := method(
    selectors = Map clone
  )
  
  selector := method(name, props,
    selectors atPut(name, props)
  )

  fromSelector := method(selectorName, prop,
    selectors at(selectorName) at(prop)
  )

  parsePropertyName := method(selector,
    selector matchesOfRegex("[A-Z]") replaceAllWith("-$0") asLowercase
  )

  parseProperty := method(property,
    property isNil ifTrue(return "none")
    property ?asMutable replaceSeq("!", "!important") replaceSeq("colour", "color")
    property
  )
  
  compile := method(
    output := "" asMutable
    selectors foreach(selectorName, selector,
      output appendSeq(selectorName .. " {")
      selector foreach(propertyName, property,
        output appendSeq(parsePropertyName(propertyName) .. ":")
        output appendSeq(parseProperty(property) .. ";")
      )
      output appendSeq("} ")
    )

    output
  )
  asString := getSlot("compile")
)
