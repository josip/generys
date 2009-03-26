Generys exceptionController do(
  privateSlots = ["status"]

  notFound := method(e,
    status(404)
    "Not Found (404)"
  )
  noRoute := getSlot("notFound")

  internalError := method(e,
    status(500)
    response statusCode = 500
    "Internal server error (500)"
  )
  wrongRequestMethod := getSlot("internalError")
  brokenRoute := getSlot("internalError")

  status := method(code, response statusCode = code)
)