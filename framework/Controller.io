Controller := Object clone do (
  request       ::= nil
  response      ::= nil
  params        ::= nil
  private       ::= nil
  privateSlots   := nil

  init := method(
    request       = nil
    response      = nil
    params        = nil
    private       = false
    privateSlots  = list()

    Generys controllers appendIfAbsent(self))

  accepts := method(
    call message arguments map(arg, arg asString) contains(request requestMethod) ifFalse(
      Exception raise("wrongRequestMethod")))

  isPOST    := method(request requestMethod == "POST")
  isGET     := method(request requestMethod == "GET")
  isPUT     := method(request requestMethod == "PUT")
  isDELETE  := method(request requestMethod == "DELETE")

  cacheFor := method(dur,
    response setHeader("Cache-Control", "max-age=" .. dur .. ", must-revalidate"))

  dontCache := method(
    response setHeader("Expires", Date fromNumber(0) asHTTPDate)
    response setHeader("Cache-Control", "no-cache, no-store"))

  forceDownload := method(filename,
    response setHeader("Content-Disposition", "attachment; filename=" .. filename))
)
Controller setSlot("SKIP_ME", 1)