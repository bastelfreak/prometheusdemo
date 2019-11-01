class roles::client {
  ensure_packages(['unzip'])
  class{'ferm':
    manage_configfile => true,
  }
  include ipset
  include nginx
  class{'consul':
    version => '1.6.1',
    require => Package['unzip'],
  }
  class{'prometheus::node_exporter':
    extra_options => '--web.listen-address 127.0.0.1:9100',
    version       => '0.18.1',
  }
}
