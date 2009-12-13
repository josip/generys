Channel := Object clone do(
  subscribers := []
  cache       := []
  cacheSize   := 20

  post := method(message, exclude,
    exclude ifNil(exclude = [])
    self subscribers foreach(subscriber,
      exclude contains(subscriber name) ifFalse(subscriber append(message) finish))

    cache append(message)
    if(cache size == cacheSize, cache removeFirst)

    message)

  streamFor := method(futureRespId, subscribers select(name == futureRespId) at(0))
)