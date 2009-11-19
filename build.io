AddonBuilder clone do(
  _build := getSlot("build")
  build = method(options,
    _build(options)
    copyBinaries)

  copyBinaries := method(
    systemCall("cp -R binaries/ ../../_build/binaries"))
)
