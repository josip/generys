Radio := Object clone do(
/*metadoc Radio description
Radio is JavaScript-like implementation of EventManager.

<pre><code>
Io> philipsRadio := Radio clone
==> Radio_0xkcd
Io> philipsRadio listenTo("Radio GaGa", method(song, artist,
  "Radio GaGa: Now playing '#{song}' by #{artist}"))
==> Radio_0xkcd
Io> philipsRadio emit("Radio GaGa", list("Is Any Wonder?", "Keane"))
Radio GaGa: Now playing 'Is it any Wonder?' by Keane.
==> Radio_0xkcd
</code></pre>
*/ 
  init := method(
    self listeners := Map clone)

  /*doc Radio listenTo(channel, callback)
  Adds radio listener.
  <code>callback</code> block will be called after <code>Radio emit()</code> is called.*/ 
  listenTo := method(channel, callback,
    self listeners hasKey(channel) ifFalse(
      self listeners atPut(channel, []))
    self listeners[channel] append(callback)
    self)

  //doc Radio listen(channel, callback) Removes callback from channel.
  removeListener := method(channel, callback,
    self listeners[channel] remove(callback)
    self)
  
  //doc Radio emit(onChannel[, args]) Calls all channel's subscribers with provided arguments.
  emit := method(onChannel, args,
    args isKindOf(List) ifFalse(args = [args])
    self listeners[onChannel] ?map(performWithArgList("call", args)))
)