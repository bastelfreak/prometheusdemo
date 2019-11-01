node prometheus {
  include roles::server
}
node centosclient {
  include roles::client
}

node archlinuxclient {
  include roles::client
}
