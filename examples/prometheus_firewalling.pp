class profiles::prometheus {
  @@ferm::rule{"prometheus2$trusted['certname']":
    ensure => 'present',
    chain  => 'INPUT',
    saddr  => facts['networking']['ip6'],
    dport  => 9100,
    proto  => 'tcp',
    policy => 'ACCEPT',
    tag    => 'prometheus2node_exporter',
  }
}

class profiles::node_exporter {
  Ferm::Rule <<| title == 'prometheus2node_exporter' |>>
}
