node prometheus {
  include roles::server
}
node centosclient {
  include roles::client
}

node archclient {
  include roles::client
}
