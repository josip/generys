/*# Taken from:
# http://pentropy.twisty-industries.com/serving-simple-dynamic-content-with-io

HTML := Object clone do (
  stack := nil
  output := nil

  init := method (
    stack = List clone
    output = List clone
  )
  
  compile := method(output join)

  squareBrackets := method (
    for (arg, 0, call argCount - 1,
      output append(call evalArgAt(arg))
    )
    output append (stack pop)
    ""
  )

  forward := method (
    name := call message name
    attrs := call message arguments map (arguments) map (pair,
      k := pair at (0) asString exSlice (1, -1)
      v := pair at (1)
      " " .. k .. "=" .. v
    ) join

    if(call message next ?name == "squareBrackets",
      output append ( "<" .. name .. attrs .. ">" )
      stack push ( "</" .. name .. ">" )
      self
    ,
      output append ( "<" .. name .. attrs .. " />" )
      ""
    )
  )
)*/

HTML := Object clone do(
  output ::= nil
  stack ::= nil
  
  init := method(
    output = ""
    stack = List clone
    log debug("HTML object is not too reliable!")
  )
  
  parseAttributes := method(attrs,
    attrs isNil or(attrs keys size == 0) ifTrue(return "")
    
    out := "" asMutable
    attrs foreach(k, v, out appendSeq(" #{k}=\"#{v}\"" interpolate))
    out
  )

  tag := method(tagName, attrs, innerHTML,
    if(attrs keys size == 0,
      parsedAttrs := "",
      parsedAttrs := parseAttributes(attrs)
    )
    
    if(innerHTML isNil or(innerHTML ?size == 0),
      "<#{tagName}#{parsedAttrs}/>",
      "<#{tagName}#{parsedAttrs}>#{innerHTML}</#{tagName}>"
    ) interpolate
  )
  
  css := method(code,
    _css := CSS clone
    _css selector("", code)
    _css compile exSlice(1, -1)
  )

  forward := method(
    tagName := call message name
    argsSize := call message arguments size

    out := if(argsSize == 0,
      tag(tagName, Map clone, nil),
      if(argsSize == 1,
        argEvaled := call evalArgAt(0)
        if(argEvaled type == "Map",
          tag(tagName, argEvaled, nil),
          tag(tagName, Map clone, argEvaled)
        ),
        tag(tagName, call evalArgAt(0), call evalArgAt(1))
      )
    ) asMutable

    if(call message next isNil,
      output = if(stack size > 0, stack pop, "") .. out,
      stack append(out)
    )

    self
  )

  # ...and the secret ingredient:
  asString := method(output)
)
