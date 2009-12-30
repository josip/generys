Radio := Object clone do(
  init := method(
    self listners := Map clone)

  listenTo := method(channel, callback,
    self listeners hasKey(channel) ifFalse(
      self listeners atPut(channel, list()))
    self listeners[channel] append(callback))

  removeListner := method(channel, callback,
    channel = self listeners[channel]
    self listeners at(channel) removeValue(callback))

  emit := method(onChannel, arg,
    self listeners [onChannel] map(call(arg)))
)