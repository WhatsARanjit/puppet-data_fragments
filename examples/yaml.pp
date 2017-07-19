$output = '/tmp/yaml.yaml'
$mp     = get_module_path('data_fragments')

concat_file { $output:
  ensure => present,
  tag    => 'demo6',
  format => 'yaml',
  force  => true,
}
concat_fragment { 'header':
  content => file("${mp}/examples/data/first.yaml"),
  order   => '01',
  target  => $output,
  tag     => 'demo6',
}
concat_fragment { 'footer plain':
  content => file("${mp}/examples/data/second.yaml"),
  order   => '10',
  target  => $output,
  tag     => 'demo6',
}
