SGML
Regex

// Notes:
//  * No support for pseudo classes
//  * Not well tested, could return wrong stuff
//  * SGMLParser messes up doctype definitions
SelectorDecomposer := Object clone do(
//metadoc SelectorDecomposer category XML
/*metadoc SelectorDecomposer description
SelectorDecomposer provides interface for querying SGMLElements similar to the one provided by jQuery.
<pre><code>
doc := """
&lt;html&gt;
  &lt;head&gt;
    &lt;title&gt;Ice creams&lt;/title&gt;
  &lt;/head&gt;
  &lt;body&gt;
    &lt;h1&gt;Ice creams&lt;/h1&gt;
    &lt;h2&gt;List of all ice cream flavours I could imagine at times moment&lt;/h2&gt;
    &lt;p&gt;
      &lt;ul id=&quot;iceCreamFlavours&quot;&gt;
        &lt;li class=&quot;firstInList&quot;&gt;Chocolate&lt;/li&gt;
        &lt;li&gt;&lt;a href=&quot;http://en.wikipedia.org/wiki/Vanilla&quot;&gt;Vanilla&lt;/a&gt;&lt;/li&gt;
        &lt;li&gt;Strawberry&lt;/li&gt;
        &lt;li&gt;Lemon&lt;/li&gt;
        &lt;li&gt;Punch&lt;/li&gt;
        &lt;li&gt;Tiramisu&lt;/li&gt;
        &lt;li&gt;&lt;a href=&quot;http://en.wikipedia.org/wiki/Banana&quot;&gt;Banana&lt;/a&gt;&lt;/li&gt;
        &lt;li&gt;Mars&lt;/li&gt;
        &lt;li&gt;Nutella&lt;/li&gt;
        &lt;li class=&quot;lastInList&quot;&gt;Pistacio&lt;/li&gt;
      &lt;/ul&gt;
    &lt;/p&gt;
  &lt;/body&gt;
&lt;/html&gt;
""" asHTML

doc find("li") map(allText)
doc findFirst("ul#iceCreamFlavours") append("&lt;li&gt;Snickers&lt;/li&gt;")
doc findFirst("li.lastInList") removeClassName("lastInList")
doc find("li") last addClassName("lastInList")
</code></pre>
*/
  # Adopted from Sizzle.js (http://sizzlejs.com/)
  chunker := "((?:\\((?:\\([^()]+\\)|[^()]+)+\\)|\\[(?:\\[[^[\\]]*\\]|['\"][^'\"]*['\"]|[^[\\]'\"]+)+\\]|\\\\.|[^ ,(\\[\\\\]+)+)(\\s*,\\s*)?" asRegex
  selectors := Object clone do(
    id      := "#((?:[\\w]|\\\\.)+)" asRegex
    class   := "\\.((?:[\\w]|\\\\.)+)" asRegex
    attr    := "\\[((?:[\\w]|\\\\.)+)s*(?:(\S?=)(['\"]*)(.*?)(['\"]*)|)\\s*]" asRegex
    tag     := "^((?:[\\w\\*-]|\\\\.)+)" asRegex
  )
  
  /*doc SelectorDecomposer decompose(selector)
    Decomposes selector. Returns Map which contains data about parts of selector
    
    Example:
    <code><pre>
    Io> SelectorDecomposer decompose("a.pLink[href=#p]") asJson
    ==> {"tag": "tag", "classes": ["pLink"], "attributes": {"href": "#p"}}</pre></code>*/
  decompose := method(selector,
  # Note: It appears that implementing cache actually would
  # only slow down the process, apparently reading from Map/Object is quite slower (2x) than
  # matching five Regexp-es (4 selectors + chunker)
    decomposed := Map clone
    decomposed atPut("tag", selector allMatchesOfRegex(self selectors tag) first ?captures ?first)
    
    attrs := Map clone
    selector allMatchesOfRegex(self selectors attr) map(match, attrs atPut(match captures at(1), match captures at(4)))
    decomposed atPut("attributes", attrs)
    attrsJoined := attrs values join(" ")

    id := selector allMatchesOfRegex(self selectors id) first ?captures ?at(1)
    // Discard cases like a[href=#id], where #id would be matched
    attrsJoined containsSeq("#" .. id) ifFalse(decomposed atPut("id", id))
    
    classes := selector allMatchesOfRegex(self selectors class) map(captures at(1)) sort
    // Discard cases like a[href=e@mail.com] where ".com" would be matched as class name
    classes select(className, attrsJoined containsSeq("." .. className)) map(className, classes remove(className))
    decomposed atPut("classes", classes)
    
    decomposed)

  //doc SelectorDecomposer split(cssQuery) Splits query into individual selectors. Returns List.
  split := method(query, query allMatchesOfRegex(self chunker) map(captures first))
)
//doc SelectorDecomposer clone Return SelectorDecomposer (singleton).
SelectorDecomposer clone = SelectorDecomposer

SGMLElement do(
  //doc SGMLElement at(index) Returns subitem at provided <code>index</code>.
  at := method(n,
    self subitems at(n))
  
  //doc SGMLElement squareBrackets(index) Alias of <code>SGMLElement at</code>.
  squareBrackets := getSlot("at")

  //doc SGMLElement isMatchedBySelector(anSelector) Tests if element matches <code>anSelector</code>.
  isMatchedBySelector := method(selector,
    (selector type == "Sequence") ifTrue(selector = SelectorDecomposer decompose(selector))
    
    reqId       := selector at("id")
    reqTag      := selector at("tag")
    reqClasses  := selector at("classes")
    reqAttrs    := selector at("attributes")
    
    if(reqId and(self attribute("id") != reqId), return(false))
    if(reqTag and(self name != reqTag), return(false))
    
    reqClasses isEmpty ifFalse(
      elClasses := self attribute("class") ?splitNoEmpties(" ")
      (elClasses containsAll(reqClasses)) ifFalse(return(false)))

    (reqAttrs keys size > self attributes size) ifTrue(return(false))
    reqAttrs map(k, v, self attribute(k) == v) contains(false) ifTrue(return(false))

    true)

  /*doc SGMLElement elementsBySelector(selector[, results])
  Returns direct children of current element which are matched by <code>selector</code>. It can be either Sequence or decomposed selector (Map returned by <code>SelectorDecomposer decompose</code>).
  <code>results</code> is an optional argument which may contain List of other elements*/
  elementsBySelector := method(selector, results,
    (selector type == "Sequence") ifTrue(selector = SelectorDecomposer decompose(selector))
    results ifNil(results = List clone)

    self isMatchedBySelector(selector) ifTrue(results append(self))
    self subitems foreach(elementsBySelector(selector, results))

    results)

  //doc SGMLElement find(query) Returns all child elements (List) relative to the caller which match query.
  find := method(query,
    query = SelectorDecomposer split(query)
    result := self elementsBySelector(query removeFirst)
    while(query size > 0,
      selector := SelectorDecomposer decompose(query removeFirst)
      result = result flatten map(elementsBySelector(selector)) flatten)

    result)

  //doc SGMLElement findFirst(query) Returns first item of result returned by <code>SGMLElement find</code>.
  findFirst := method(query, self find(query) first)

  //doc SGMLElement adopt(htmlCode) Converts <code>htmlCode</code> to SGMLElement and sets caller as its parent.
  adopt := method(el,
    (el type == "Sequence") ifTrue(el = el asHTML)
    el subitems mapInPlace(setParent(self parent)))
  
  //doc SGMLElement append(element) Appends <code>element</code> at the end of the caller element.
  append := method(el,
    self adopt(el) foreach(el, self subitems append(el))
    self)
  
  //doc SGMLElement prepend(element) Appends <code>element</code> at the bottom of the caller element.
  prepend := method(el,
    self adopt(el) foreach(el, self subitems prepend(el))
    self)

  //doc SGMLElement positionInParent Returns index at which current element is in its parent.
  positionInParent := method(self parent subitems indexOf(self))

  //doc SGMLElement prev([move]) Returns element before the caller.
  prev := method(move,
    move ifNil(move = 1)
    
    el := self parent subitems at(self positionInParent - move)
    el ifNil(return(nil))
    # TODO: Why tailCall(move + 1) isn't working here?
    if(el name isNil, self prev(move + 1), el))
  
  //doc SGMLElement next([move]) Returns element after the caller.
  next := method(move,
    move ifNil(move = 1)
    
    el := self parent subitems at(self positionInParent + move)
    el ifNil(return(nil))
    if(el name isNil, self next(move + 1), el))

  //doc SGMLElement insertBefore(element) Inserts element before caller in caller's parent.
  insertBefore := method(el,
    pos := self positionInParent
    self adopt(el) reverse foreach(el, self parent subitems insertAt(el, pos))
    self)

  //doc SGMLElement insertAfter(element) Inserts element after caller in caller's parent.
  insertAfter := method(el,
    self adopt(el) foreach(el,
      self parent subitems insertAt(el, self positionInParent + 1))
    self)

  //doc SGMLElement root Returns root element.
  root := method(
    (node := self parent) returnIfNil
    while(node parent, node = node parent)
    node)
  
  //doc SGMLElement setAttribute(attributeName, value) Sets attribute.
  setAttribute := method(name, value,
    self attributes atPut(name, value)
    self)

  //doc SGMLElement addClassName(className) Adds class name to caller if absent.
  addClassName := method(className,
    self setAttribute("class", self attributes at("class") split(" ") appendIfAbsent(name) join(" ")))
  
  //doc SGMLElement removeClassName(className) Removes class name from caller.
  removeClassName := method(className,
    self setAttribute("class", self attributes at("class") split(" ") remove(className) join(" ")))
)

HTML := SGML
//metadoc HTML category XML
//metadoc HTML description Alias for <a href="#SGML">SGML</a>.
//doc HTML fromFile(file) Returns file's content as SGMLDocument. <code>file</code> can be both Sequence and File.
HTML fromFile := method(file,
  (file type == "Sequence") ifTrue(file = File openForReading(file))
  text := file contents
  file close
  text asHTML)