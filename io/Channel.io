Channel := Object clone do(
//metadoc Channel category Networking
/*metadoc Channel description
Channel provides seamless integration of FutureResponse and WebSocket implementations.
*/
  subscribers := list()
  cache       := list()
  cacheSize   := 20

  //doc Channel subscribe(subscriber) Adds subscriber to channel. Subscriber is eiter FutureResponse, either WebSocket object
  subscribe := method(subscriber,
    self subscribers append(subscriber)
    subscriber)

  /*doc Channel send(message, excludeList)
  Send message to all subscribers.
  <code>excludeList</code> can contain list of subscribers (their <code>name</code> properties) to which message won't be sent.*/
  send := method(msg, exclude,
    exclude ifNil(exclude = [])
    sent := 0
    
    self subscribers foreach(subscriber,
      exclude contains(subscriber name) ifFalse(
        sent = sent + 1
        subscriber send(msg) ?finish))

    log debug("Sent message to #{sent} subscribers (#{exclude size} subscribers excluded)")

    cache append(msg)
    if(cache size == cacheSize, cache removeFirst)

    msg)

  //doc Channel streamFor(subscriberName) Returns FutureResponse or WebSocket with provided name
  streamFor := method(streamName, subscribers select(name == streamName) at(0))
)