#!/usr/bin/env io

list("framework/", "lib/") foreach(path, Importer addSearchPath(path))

Generys do(
  root := Directory currentWorkingDirectory asString
  publicDir := Generys root .. "/public"
  config do(doFile("config/default.json") asObject)
)

doFile("config/routes.io")

Directory clone with("controllers/") doFiles

Generys start
