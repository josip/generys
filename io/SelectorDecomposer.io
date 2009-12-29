SGML
Regex

// Known bugs:
//  * Attributes with # and . will be interpreted as ids and classes respectively
//  * No support for pseudo classes
//  * Not well tested, could return wrong items
//  * NOTE: SGMLParser messes up doctype definitions
SelectorDecomposer := Object clone do(
  # Adopted from Sizzle.js (http://sizzlejs.com/)
  chunker := "((?:\\((?:\\([^()]+\\)|[^()]+)+\\)|\\[(?:\\[[^[\\]]*\\]|['\"][^'\"]*['\"]|[^[\\]'\"]+)+\\]|\\\\.|[^ ,(\\[\\\\]+)+)(\\s*,\\s*)?" asRegex
  selectors := Object clone do(
    id      := "#((?:[\\w]|\\\\.)+)" asRegex
    class   := "\\.((?:[\\w]|\\\\.)+)" asRegex
    attr    := "\\[((?:[\\w]|\\\\.)+)s*(?:(\S?=)(['\"]*)(.*?)(['\"]*)|)\\s*]" asRegex
    tag     := "^((?:[\\w\\*-]|\\\\.)+)" asRegex
  )
  
  # Note: It appears that implementing cache actually would
  # only slow down the process, apparently reading from Map/Object is quite slower (2x) than
  # matching five Regexp-es (4 selectors + chunker)
  decompose := method(selector,
    decomposed := Map clone
    decomposed atPut("tag", selector allMatchesOfRegex(self selectors tag) at(0) ?captures ?at(0))
    
    attrs := Map clone
    selector allMatchesOfRegex(self selectors attr) map(match, attrs atPut(match captures at(1), match captures at(4)))
    decomposed atPut("attributes", attrs)
    attrsJoined := attrs values join(" ")

    id      := selector allMatchesOfRegex(self selectors id) at(0) ?captures ?at(1)
    // Discard cases like a[href=#id], where #id would be matched
    attrsJoined containsSeq("#" .. id) ifFalse(decomposed atPut("id", id))
    
    classes := selector allMatchesOfRegex(self selectors class) map(captures at(1)) sort
    // Discard cases like a[href=e@mail.com] where ".com" would be matched as class name
    classes select(className, attrsJoined containsSeq("." .. className)) map(className, classes remove(className))
    decomposed atPut("classes", classes)
    
    decomposed)

  split := method(query, query allMatchesOfRegex(self chunker) map(captures at(0)))
)
SelectorDecomposer clone = SelectorDecomposer

SGMLElement do(
  isMatchedBySelector := method(selector,
    (selector type == "Sequence") ifTrue(selector = SelectorDecomposer decompose(selector))
    
    reqId       := selector at("id")
    reqTag      := selector at("tag")
    reqClasses  := selector at("classes")
    reqAttrs    := selector at("attributes")
    
    if(reqId and (self attribute("id") != reqId), return(false))
    if(reqTag and(self name != reqTag), return(false))
    
    reqClasses isEmpty ifFalse(
      elClasses := self attribute("class") ?splitNoEmpties(" ") ?sort
      (elClasses == reqClasses) ifFalse(return(false)))

    (reqAttrs keys size > self attributes size) ifTrue(return(false))
    reqAttrs map(k, v, self attribute(k) == v) contains(false) ifTrue(return(false))

    true)

  elementsBySelector := method(selector, results,
    (selector type == "Sequence") ifTrue(selector = SelectorDecomposer decompose(selector))
    results ifNil(results = List clone)

    self isMatchedBySelector(selector) ifTrue(results append(self))
    self subitems foreach(elementsBySelector(selector, results))

    results)

  find := method(query,
    query = SelectorDecomposer split(query)
    result := self elementsBySelector(query removeFirst)
    while(query size > 0,
      selector := SelectorDecomposer decompose(query removeFirst)
      result = result flatten map(elementsBySelector(selector)) flatten)

    result)
  
  findFirst := method(query, self find(query) at(0))
  
  adopt := method(el,
    (el type == "Sequence") ifTrue(el = el asHTML)
    el subitems mapInPlace(setParent(self parent)))
    
  append := method(el,
    self adopt(el) foreach(el, self subitems append(el))
    self)
  prepend := method(el,
    self adopt(el) foreach(el, self subitems prepend(el))
    self)

  positionInParent := method(self parent subitems indexOf(self))

  prev := method(move,
    move ifNil(move = 1)
    
    el := self parent subitems at(self positionInParent - move)
    el ifNil(return(nil))
    // TODO: Why tailCall(move + 1) isn't working here?
    if(el name isNil, self prev(move + 1), el))
    
  next := method(move,
    move ifNil(move = 1)
    
    el := self parent subitems at(self positionInParent + move)
    el ifNil(return(nil))
    if(el name isNil, self next(move + 1), el))

  insertBefore := method(el,
    pos := self positionInParent
    self adopt(el) reverse foreach(el, self parent subitems insertAt(el, pos))
    self)

  insertAfter := method(el,
    self adopt(el) foreach(el,
      self parent subitems insertAt(el, self positionInParent + 1))
    self)

  root := method(
    (node := self parent) returnIfNil
    while(node parent, node = node parent)
    node)
)

HTML := SGML
HTML fromFile := method(file,
  (file type == "Sequence") ifTrue(file = File openForReading(file))
  text := file contents
  file close
  text asHTML)