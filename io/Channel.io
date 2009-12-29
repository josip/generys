Channel := Object clone do(
  subscribers := list()
  cache       := list()
  cacheSize   := 20

  subscribe := method(subscriber,
    self subscribers append(subscriber)
    subscriber)

  send := method(message, exclude,
    exclude ifNil(exclude = [])
    sent := 0
    
    self subscribers foreach(subscriber,
      exclude contains(subscriber name) ifFalse(
        sent = sent + 1
        subscriber send(message) ?finish))

    log debug("Sent message to #{sent} subscribers (#{exclude size} subscribers excluded)")

    cache append(message)
    if(cache size == cacheSize, cache removeFirst)

    message)

  streamFor := method(streamName, subscribers select(name == streamName) at(0))
)