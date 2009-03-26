Generys do (
  host                := "127.0.0.1"
  port                := 8080
  # Possible values: all, debug, info, error, none
  log_level           := "info"
  # If you are using Cherokee web server (and you should!)
  # you can set this to +true+ as Cherokee will take care of
  # presenting the file to the user while saving Generys from all the hard work
  x_sendfile_header   := false
)
