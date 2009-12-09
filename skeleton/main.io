#!/usr/bin/env io

list("framework/io", "lib/", "app/models", "app/controllers") foreach(path,
  Importer addSearchPath(path))

Generys do(
  root      := Directory currentWorkingDirectory
  staticDir := Generys root .. "/static"
  tmpDir    := Generys root .. "/tmp"
  
  loadConfig
)

System launchScript containsSeq("main.io") ifTrue(Generys run)