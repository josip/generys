IoExtensions := Object clone

Object do(
  //doc Object squareBrackets(...) Alias for list(). <code><pre>[1, 2, 3, 4]</pre></code>
  squareBrackets := getSlot("list")
  
  /*doc Object curlyBrackets(...)
  JavaScript syntax for Map.<br/>
  Note that order will not be preserved, as well as that quotes are not allowed around propery names (as in JSON specification).
  <code><pre>
  prices:= {
    vanilla:    12.20,
    chocolate:  12.25,
    strawberry: 13.30
  }</pre></code>*/
  curlyBrackets := method(
    map := Map clone
    call message arguments foreach(arg,
      map atPut(arg name, arg next next doInContext(call sender)))
    map)

  //doc Object asMap() Converts Object to Map
  asMap := method(
    slots := self slotNames map(slotName, self getSlot(slotName))
    Map clone addKeysAndValues(self slotNames, slots))

  //doc Object asJson() Converts Object to JSON Sequence.
  asJson := method(self asMap asJson)
)

/*doc List squareBrackets
Allows access to List, Map and Sequence elements with syntax common in other languages.
<code><pre>
Io> colours := ["Brown", "Blue", "Violet sky"]
==> list("Brown", "Blue", "Violet sky")
Io> colours[0]
==> "Brown"
Io> colours[1,2]
=> list("Blue", "Violet sky")
Io> prices["chocolate"]
==> 12.25
Io> prices["chocolate", "strawberry"] sum
==> 25.75
</pre></code>*/
List squareBrackets := Map squareBrackets := Sequence squareBrackets := method(
  evaled := call message argsEvaluatedIn(call sender)
  if(evaled size == 1,
    self at(evaled at(0))
  ,
    if(self isKindOf(Map),
      self select(key, evaled contains(key)),
      self exSlice(evaled at(0), evaled at(1)))
  ))

# You probably don't want to show your code to the world?
//doc Block asJson Returns "null".
Block proto asJson := "null"
//doc nil asJson Returns "null".
nil asJson  := "null"
//doc nil ifTrue() Returns <code><nil/code>.
nil ifTrue  := method(nil)
//doc nil ifFalse(code)  Calls and returns result of <code>code</code>.
nil ifFalse := method(call evalArgAt(0))

//doc Message setArgAt(index, value) Clones message arguments and replaces value of a argument at <code>index</code>.
Message setArgAt := method(index, arg,
  self setArguments(self arguments clone atPut(index, arg)))

Map do(
  //doc Map fromKeysAndValues(keys, values) Creates new values from list of keys and values.
  fromKeysAndValues := method(keys, values,
    self clone addKeysAndValues(keys, values))

  //doc Map mapValues(key, value, message)
  mapValues := method(
    Map fromKeysAndValues(self keys, call delegateToMethod(self, "map")))

  //doc Map removeIf(key, value, message) Removes all properties for which <code>message</code> returns <code>true</code>.
  removeIf := method(
    result := self clone
    call delegateToMethod(result, "select") foreach(k, v, result removeAt(k))
    result)
)

List do (
  //doc Map removeIf(key, value, message) Removes all items for which <code>message</code> is <code>true</code>.
  removeIf := Map getSlot("removeIf")
)

Date do(
  //doc Date asHTTPDate() Returns Date as Sequence in HTTP format.
  asHTTPDate := method(
    self asString("%a, %d %b %Y %H:%M:%S %Z"))

  //doc Date asJson() Converts date to UTC and converts it to format which most JSON parsers understand.
  asJson := method(
    self convertToUTC asString("%Y-%m-%dT%H:%M:%SZ") asJson)
)

Directory do(
  //doc Directory doFiles() Executes all .io files in given directory. 
  doFiles := method(
    p := self path
    self fileNames foreach(fileName,
      fileName containsSeq(".io") ifTrue(doFile(p .. "/" .. fileName))))

  //doc Directory mimeType Returns "application/x-not-regular-file".
  mimeType := "application/x-not-regular-file"
)

# List of most common mime-types, stolen from Rack.
//doc File mimeTypes Map of known MIME type with file extension as key.
File mimeTypes := {
  #3gp:      "video/3gpp",
  a:        "application/octet-stream",
  ai:       "application/postscript",
  aif:      "audio/x-aiff",
  aiff:     "audio/x-aiff",
  asc:      "application/pgp-signature",
  asf:      "video/x-ms-asf",
  asm:      "text/x-asm",
  asx:      "video/x-ms-asf",
  atom:     "application/atom+xml",
  au:       "audio/basic",
  avi:      "video/x-msvideo",
  bat:      "application/x-msdownload",
  bin:      "application/octet-stream",
  bmp:      "image/bmp",
  bz2:      "application/x-bzip2",
  c:        "text/x-c",
  cab:      "application/vnd.ms-cab-compressed",
  cc:       "text/x-c",
  chm:      "application/vnd.ms-htmlhelp",
  class:    "application/octet-stream",
  com:      "application/x-msdownload",
  conf:     "text/plain",
  cpp:      "text/x-c",
  crt:      "application/x-x509-ca-cert",
  css:      "text/css",
  csv:      "text/csv",
  cxx:      "text/x-c",
  deb:      "application/x-debian-package",
  der:      "application/x-x509-ca-cert",
  diff:     "text/x-diff",
  djv:      "image/vnd.djvu",
  djvu:     "image/vnd.djvu",
  dll:      "application/x-msdownload",
  dmg:      "application/octet-stream",
  doc:      "application/msword",
  dot:      "application/msword",
  dtd:      "application/xml-dtd",
  dvi:      "application/x-dvi",
  ear:      "application/java-archive",
  eml:      "message/rfc822",
  eps:      "application/postscript",
  exe:      "application/x-msdownload",
  f:        "text/x-fortran",
  f77:      "text/x-fortran",
  f90:      "text/x-fortran",
  flv:      "video/x-flv",
  for:      "text/x-fortran",
  gem:      "application/octet-stream",
  gemspec:  "text/x-script.ruby",
  gif:      "image/gif",
  gz:       "application/x-gzip",
  h:        "text/x-c",
  hh:       "text/x-c",
  htm:      "text/html",
  html:     "text/html",
  ico:      "image/vnd.microsoft.icon",
  ics:      "text/calendar",
  ifb:      "text/calendar",
  iso:      "application/octet-stream",
  jar:      "application/java-archive",
  java:     "text/x-java-source",
  jnlp:     "application/x-java-jnlp-file",
  jpeg:     "image/jpeg",
  jpg:      "image/jpeg",
  js:       "application/javascript",
  json:     "application/json",
  log:      "text/plain",
  m3u:      "audio/x-mpegurl",
  m4v:      "video/mp4",
  man:      "text/troff",
  mathml:   "application/mathml+xml",
  mbox:     "application/mbox",
  mdoc:     "text/troff",
  me:       "text/troff",
  mid:      "audio/midi",
  midi:     "audio/midi",
  mime:     "message/rfc822",
  mml:      "application/mathml+xml",
  mng:      "video/x-mng",
  mov:      "video/quicktime",
  mp3:      "audio/mpeg",
  mp4:      "video/mp4",
  mp4v:     "video/mp4",
  mpeg:     "video/mpeg",
  mpg:      "video/mpeg",
  ms:       "text/troff",
  msi:      "application/x-msdownload",
  odp:      "application/vnd.oasis.opendocument.presentation",
  ods:      "application/vnd.oasis.opendocument.spreadsheet",
  odt:      "application/vnd.oasis.opendocument.text",
  ogg:      "application/ogg",
  p:        "text/x-pascal",
  pas:      "text/x-pascal",
  pbm:      "image/x-portable-bitmap",
  pdf:      "application/pdf",
  pem:      "application/x-x509-ca-cert",
  pgm:      "image/x-portable-graymap",
  pgp:      "application/pgp-encrypted",
  pkg:      "application/octet-stream",
  pl:       "text/x-script.perl",
  pm:       "text/x-script.perl-module",
  png:      "image/png",
  pnm:      "image/x-portable-anymap",
  ppm:      "image/x-portable-pixmap",
  pps:      "application/vnd.ms-powerpoint",
  ppt:      "application/vnd.ms-powerpoint",
  ps:       "application/postscript",
  psd:      "image/vnd.adobe.photoshop",
  py:       "text/x-script.python",
  qt:       "video/quicktime",
  ra:       "audio/x-pn-realaudio",
  rake:     "text/x-script.ruby",
  ram:      "audio/x-pn-realaudio",
  rar:      "application/x-rar-compressed",
  rb:       "text/x-script.ruby",
  rdf:      "application/rdf+xml",
  roff:     "text/troff",
  rpm:      "application/x-redhat-package-manager",
  rss:      "application/rss+xml",
  rtf:      "application/rtf",
  ru:       "text/x-script.ruby",
  s:        "text/x-asm",
  sgm:      "text/sgml",
  sgml:     "text/sgml",
  sh:       "application/x-sh",
  sig:      "application/pgp-signature",
  snd:      "audio/basic",
  so:       "application/octet-stream",
  svg:      "image/svg+xml",
  svgz:     "image/svg+xml",
  swf:      "application/x-shockwave-flash",
  t:        "text/troff",
  tar:      "application/x-tar",
  tbz:      "application/x-bzip-compressed-tar",
  tcl:      "application/x-tcl",
  tex:      "application/x-tex",
  text:     "application/x-texinfo",
  texinfo:  "application/x-texinfo",
  text:     "text/plain",
  tif:      "image/tiff",
  tiff:     "image/tiff",
  torrent:  "application/x-bittorrent",
  tr:       "text/troff",
  txt:      "text/plain",
  vcf:      "text/x-vcard",
  vcs:      "text/x-vcalendar",
  vrml:     "model/vrml",
  war:      "application/java-archive",
  wav:      "audio/x-wav",
  wma:      "audio/x-ms-wma",
  wmv:      "video/x-ms-wmv",
  wmx:      "video/x-ms-wmx",
  wrl:      "model/vrml",
  wsdl:     "application/wsdl+xml",
  xbm:      "image/x-xbitmap",
  xhtml:    "application/xhtml+xml",
  xls:      "application/vnd.ms-excel",
  xml:      "application/xml",
  xpm:      "image/x-xpixmap",
  xsl:      "application/xml",
  xslt:     "application/xslt+xml",
  yaml:     "text/yaml",
  yml:      "text/yaml",
  zip:      "application/zip"
}

File do(
  //doc File ext() Returns file's extension. (Letters after last ".")
  ext := method(self name split(".") last)
  //doc File mimeType() Returns file's MIME type.
  mimeType := method(File mimeTypes[self ext])
)