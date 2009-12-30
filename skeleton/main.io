#!/usr/bin/env io

list("framework/io", "lib/", "app/models", "app/controllers") foreach(path,
  Importer addSearchPath(path))

Generys do(
  root      := Directory currentWorkingDirectory
)

if(System launchScript ?containsSeq("main.io"), Generys serve)
