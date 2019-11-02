class roles::server {
  # epel is needed by foreman and ferm
  # foreman could provide epel for us, but we need to apply the basiscs class before :(
  $osreleasemajor = $facts['os']['release']['major']
  $epel_gpgkey = $osreleasemajor ? {
    '7'     => 'https://fedoraproject.org/static/352C64E5.txt',
    default => 'https://fedoraproject.org/static/0608B895.txt',
  }
  yumrepo { 'epel':
    descr      => "Extra Packages for Enterprise Linux ${osreleasemajor} - \$basearch",
    mirrorlist => "https://mirrors.fedoraproject.org/metalink?repo=epel-${osreleasemajor}&arch=\$basearch",
    baseurl    => "http://download.fedoraproject.org/pub/epel/${osreleasemajor}/\$basearch",
    enabled    => 1,
    gpgcheck   => 1,
    gpgkey     => $epel_gpgkey,
  }

  # the whole point of this is that we need a puppetserver that automatically sign certificate requests
  class{'puppet':
    # Don't configure the agent
    agent                           => false,
    # configure the server
    server                          => true,
    # don't integrate with foreman
    server_foreman                  => false,
    # 3 settings: dev environment, just sign every request
    autosign                        => true,
    server_ca_allow_sans            => true,
    server_ca_allow_auth_extensions => true,
    # Setup Puppet 5, not 6
    server_puppetserver_version     => '5.3.10',
    # dont create /etc/puppetlabs/code/environments/common
    server_common_modules_path      => '',
    # don't leak private data to Puppet Inc.
    server_check_for_updates        => false,
    # store puppet reports on disk, dont send them to foreman
    server_reports                  => 'store',
    # Don't configure an ENC script
    server_external_nodes           => '',
    # use a modern parser
    server_strict_variables         => true,
    require                         => Yumrepo['epel'],
  }


  ensure_packages(['unzip'])
  class{'consul':
    version        => '1.6.1',
    config_dir     => '/etc/consul.d',
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
      'encrypt'              => 'biFfI6Ru5Opbv3PpbgIQsm3IyFt3vhOsVZKHYndtd/g=',
      'verify_outgoing'      => true,
      'verify_incoming'      => true,
      'ca_file'              => '/etc/puppetlabs/puppet/ssl/certs/ca.pem',
      'cert_file'            => "/etc/puppetlabs/puppet/ssl/certs/${trusted['certname']}.pem",
      'key_file'             => "/etc/consul.d/${trusted['certname']}.pem",
      'enable_script_checks' => true,
      'ui'                   => true,
    },
    require        => Package['unzip'],
  }
  file { "/etc/consul.d/${trusted['certname']}.pem":
    ensure         => 'file',
    owner          => 'consul',
    group          => 'consul',
    mode           => '0400',
    source         => "/etc/puppetlabs/puppet/ssl/private_keys/${trusted['certname']}.pem",
    notify         => Class['consul::reload_service'],
  }

  class{'prometheus::server':
    version => '2.13.1',
    extra_options  => '--web.enable-admin-api',
    scrape_configs => [
      {
        'job_name' => 'prometheus',
        'scrape_interval' => '10s',
        'scrape_timeout' => '10s',
        'static_configs' => [
        {
          'targets' => [
            'localhost:9090'
          ],
          'labels' =>
            {
              'alias' => 'Prometheus'
            }
          }
          ]
      },
      {
        'job_name'          => 'node_exporter',
        'scrape_interval'   => '10s',
        'scrape_timeout'    => '10s',
        'scheme'            => 'https',
        'tls_config'        => {
          'ca_file'   => '/etc/prometheus/ca.pem',
          'cert_file' => "/etc/prometheus/cert_${trusted['certname']}.pem",
          'key_file'  => "/etc/prometheus/key_${trusted['certname']}.pem"
        },
        'consul_sd_configs' => [
          {
            'server'   => 'localhost:8500',
            'services' => ['node_exporter'],
            'scheme'   => 'http'
          }
        ]
      }
    ],
  }
  class{'prometheus::node_exporter':
    extra_options => '--web.listen-address 127.0.0.1:9100',
    version       => '0.18.1',
  }

  include nginx

  class{'ferm':
    manage_configfile => true,
    manage_service    => true,
    input_policy      => 'ACCEPT',
  }
  ferm::chain { 'CONSUL':
    disable_conntrack   => true,
    log_dropped_packets => false,
  }
  ferm::rule { 'jump_consul_chain':
    chain   => 'INPUT',
    action  => 'CONSUL',
    proto   => ['udp', 'tcp'],
    dport   => '(8301 8302)',
    require => Ferm::Chain['CONSUL'],
  }

  include ipset
  ipset::set{'rfc1918':
    ensure  => 'present',
    set     => ['10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16'],
    type    => 'hash:net',
  }
  ferm::ipset{'CONSUL':
    sets       => {
      'rfc1918' => 'ACCEPT',
    },
    require    => Ipset::Set['rfc1918'],
  }

}
