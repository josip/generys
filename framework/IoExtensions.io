IoExtensions := block do(
  Object squareBrackets := Object getSlot("list")

  Object curlyBrackets := method(
	  map := Map clone
	  call message arguments foreach(arg,
	    evaled := arg argsEvaluatedIn(call sender)
	    map atPut(evaled at(0), evaled at(1))
	  )
	  map
  )
    
  #List proto squareBrackets := method(index, self at(index))
  #List proto curlyBrackets := method(start, end, self exSlice(start, end))
  #Map proto squareBracktes := method(key, self at(key))

  Date proto asHTTPDate := method(self asString("%a, %d %b %Y %H:%M:%S %Z"))
  
  Directory proto doFiles := method(
    self fileNames foreach(fileName, doFile(path .. fileName))
  )
)
