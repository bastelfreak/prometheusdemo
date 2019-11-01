class profiles::node_exporter {
  # install consul
  $ipfact = "networking.ip6"
  $ipv6 = $facts['networking']['ip6']
  $consulnodeips = query_nodes("Class[Roles::Consul] and $ipfact != '${ipv6}'", $ipfact)
  $config_hash = {
    'bind_addr'            => facts['networking']['ip6'],
    'data_dir'             => '/opt/consul',
    'datacenter'           => 'DE',
    'log_level'            => 'INFO',
    'node_name'            => $trusted['certname'],
    'server'               => false,
    'disable_update_check' => true,
    'encrypt'              => 'my_magic_key',
    'key_file'             => "/etc/consul.d/${trusted['certname']}.pem",
    'retry_join'           => map(sort($consulnodeips)) |$ip| { "[${ip}]" },
    'enable_script_checks' => true,
  }
  class { 'consul':
    pretty_config   => true,
    bin_dir         => '/usr/bin',
    config_dir      => '/etc/consul.d',
    extra_options   => '-raft-protocol 3',
    config_hash     => $config_hash,
    enable_beta_ui  => false,
    require         => Package['unzip'],
  }

  # register node exporter in consul
  consul::service { 'node_exporter':
    checks => [
      {
        name     => 'node_exporter health check',
        http     => 'http://127.0.0.1:9100',
        interval => '10s',
        timeout  => '1s'
      }
    ],
    port   => 9100,
    address => $trusted['certname'],
    tags    => ['node_exporter']
  }
}
