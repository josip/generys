#!/usr/bin/env io

Importer turnOn
list("framework/", "lib/") foreach(path, Importer addSearchPath(path))

Generys root := Directory currentWorkingDirectory clone
Generys publicDir := Generys root .. "/public" 

Directory clone with("config/") doFiles
Directory clone with("controllers/") doFiles

Generys start
