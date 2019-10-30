class roles::server {
  ensure_packages(['unzip'])
  class{'consul':
    version        => '1.6.1',
    pretty_config  => true,
    enable_beta_ui => true,
    config_hash    => {
      'bind_addr'            => $facts['networking']['ip'],
      'bootstrap_expect'     => 1,
      'data_dir'             => '/opt/consul',
      'datacenter'           => 'NBG',
      'log_level'            => 'INFO',
      'node_name'            => $facts['fqdn'],
      'server'               => true,
      'disable_update_check' => true,
      'enable_script_checks' => true,
      'ui'                   => true,
    },
    require        => Package['unzip'],
  }
  include prometheus
  include nginx
}
