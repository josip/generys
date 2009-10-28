#!/usr/bin/env io

list("framework/", "lib/") foreach(path, Importer addSearchPath(path))

Generys do(
  root := Directory currentWorkingDirectory asString
  publicDir := Generys root .. "/public"
  env := "dev"
  config do(doFile("config/environment/" .. (Generys env) .. ".json") asObject)
)

doFile("config/routes.io")

Directory clone with("controllers/") doFiles

Generys start
