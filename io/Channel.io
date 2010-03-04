Channel := Object clone do(
//metadoc Channel category Networking
/*metadoc Channel description
Channel provides seamless integration of FutureResponse and WebSocket implementations.
*/
  subscribers := list()
  cache       := list()
  cacheSize   := 20

  //doc Channel subscribe(subscriber) Adds subscriber to the channel. Subscriber can be FutureResponse or WebSocket object. Returns <code>subscriber</code>.
  subscribe := method(subscriber,
    subscriber setChannel(self)
    self subscribers append(subscriber)
    subscriber)
  
  //doc Channel unsubscribe(subscriber) Removes subscriber from self. Returns <code>self</code>.
  unsubscribe := method(subscriber,
    subscriber setChannel(nil)
    self subscribers remove(subscriber)
    self)

  /*doc Channel send(message, excludeList)
  <p>Send message to all subscribers. Returns <code>message</code>.</p>
  <p><code>excludeList</code> can contain list of subscribers (their <code>name</code> properties) to which message won't be sent.</p>*/
  send := method(msg, excludeList,
    excludeList ifNil(excludeList = [])

    sentTo := self subscribers select(subscriber,
      excludeList contains(subscriber name) not ifTrue(
        subscriber send(msg) ?finish)) size

    log debug("[Channel] Message sent to #{sentTo} subscribers (#{excludeList size} subscribers excluded)")

    # Cache is for FutureResponse
    cache append(msg)
    if(cache size >= cacheSize, cache removeFirst)

    msg)

  //doc Channel streamFor(subscriberName) Returns FutureResponse or WebSocket with provided name
  streamFor := method(streamName, subscribers detect(name == streamName))
)