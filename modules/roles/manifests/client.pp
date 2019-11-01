class roles::client {
  ensure_packages(['unzip'])

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

  class{'ferm':
    manage_configfile => true,
    require           => Yumrepo['epel'],
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
