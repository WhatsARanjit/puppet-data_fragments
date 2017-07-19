$output = '/tmp/json.json'
$mp     = get_module_path('data_fragments')

concat_file { $output:
  ensure => present,
  tag    => 'demo3',
  format => 'json',
  force  => true,
}
concat_fragment { 'header':
  content => file("${mp}/examples/data/first.json"),
  order   => '01',
  target  => $output,
  tag     => 'demo3',
}
concat_fragment { 'footer plain':
  content => file("${mp}/examples/data/second.json"),
  order   => '10',
  target  => $output,
  tag     => 'demo3',
}
