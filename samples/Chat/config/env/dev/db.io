CouchDB

Object do(
  DB := CouchDB with("localhost", "chat")
  DB clone = DB
  CouchDB default := DB
)