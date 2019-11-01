class profiles::node_exporter {
  # An Array of array with IPv4 and IPv6 addresses
  $ip_ranges = lookup('vlans').flatten.unique
  $ip_ranges_ipv6 = $ip_ranges.filter |$ip_range| { $ip_range =~ Stdlib::IP::Address::V6 }

  ipset::set{'nodes_v6':
    ensure  => 'present',
    set     => $ip_ranges_ipv6,
    type    => 'hash:net',
    options => {
      'family' => 'inet6',
    },
  }
  # create chain for consul stuff
  -> ferm::chain { 'CONSUL':
    disable_conntrack   => true,
    log_dropped_packets => false,
  }
  -> ferm::rule { 'jump_consul_chain':
    chain  => 'INPUT',
    action => 'CONSUL',
    proto  => ['udp', 'tcp'],
    dport  => '(8301 8302)',
  }
  -> ferm::ipset{'CONSUL':
    ip_version => 'ip6',
    sets       => {
      'nodes_v6' => 'ACCEPT',
    },
  }
  unless (stdlib::ip_in_range($facts['networking']['ip6'], $ip_ranges_ipv6)) {
    @@ferm::rule { "allow_consul_agent2agent-${trusted['certname']}":
      chain   => 'CONSUL',
      action  => 'ACCEPT',
      proto   => 'all',
      saddr   => $facts['networking']['ip6'],
      tag     => 'allow_consul_agent2agent',
      require => Ferm::Chain['CONSUL'],
    }
    # allow client-agents to communicate with master-agents
    @@ferm::rule { "allow_consul_client2server-${trusted['certname']}":
      chain  => 'INPUT',
      action => 'CONSUL',
      proto  => 'tcp',
      dport  => 8300,
      saddr  => $facts['networking']['ip6'],
      tag    => 'allow_consul_client2server',
    }
  }

  # collect all exported resources with the tag allow_consul_agent2agent
  # We assume that only nodes that aren't in the range export rules
  Ferm::Rule <<| tag == 'allow_consul_agent2agent' |>>
}
