class roles::client {
  include ferm
  include ipset
  include nginx
  include consul
  class{'prometheus::node_exporter':
    extra_options => '--web.listen-address 127.0.0.1:9100',
    version       => '0.18.1',
  }
}
