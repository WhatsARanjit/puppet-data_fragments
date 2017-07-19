# data_fragments

#### Table of Contents

1. [Overview](#overview)
1. [Easy example](#easy-example)
1. [Usage](#usage)
1. [Types](#types)

## Overview

The data_fragments module lets you construct data files from multiple ordered fragments of data

## Easy example

To start using data_fragments you need to create:

* A `data_file`  resource for the final file.
* One or more `data_fragment`s.

A minimal example might be:

~~~
data_file { '/tmp/file':
  ensure => present,
  tag    => 'demo',
}

data_fragment { 'tmpfile':
  target  => '/tmp/file',
  content => 'test contents',
  order   => '01'
  tag     => 'demo',
}
~~~

## Usage

Check the [examples](examples) directory for example uses of `json`, `json-pretty`, and `yaml`.

## Types

### Type: `data_file`

##### `backup`

Data type: String, Boolean. 

Specifies whether (and how) to back up the destination file before overwriting it. Your value gets passed on to Puppet's [native `file` resource](https://docs.puppetlabs.com/references/latest/type.html#file-attribute-backup) for execution. Valid options: `true`, `false`, or a string representing either a target filebucket or a filename extension beginning with ".".

Default value: 'puppet'.

##### `ensure`

Data type: String.

Specifies whether the destination file should exist. Setting to 'absent' tells Puppet to delete the destination file if it exists, and negates the effect of any other parameters. Valid options: 'present' and 'absent'. 

Default value: 'present'.

##### `ensure_newline`

Data type: Boolean.

Specifies whether to add a line break at the end of each fragment that doesn't already end in one. Valid options: `true` and `false`.

Default value: `false`.

##### `group`

Data type: String, Integer.

Specifies a permissions group for the destination file. Valid options: a string containing a group name. 

Default value: `undef`.

##### `mode`

Data type: String.

Specifies the permissions mode of the destination file. Valid options: a string containing a permission mode value in octal notation. 

Default value: '0644'.

##### `order`

Data type: String.

Specifies a method for sorting your fragments by name within the destination file. Valid options: 'alpha' (e.g., '1, 10, 2') or 'numeric' (e.g., '1, 2, 10'). 

You can override this setting for individual fragments by adjusting the `order` parameter in their `data_fragment` declarations.

Default value: 'numeric'.

##### `owner`

Data type: String, Integer.

Specifies the owner of the destination file. Valid options: a string containing a username. 

Default value: `undef`.

##### `path`

Data type: String.

Specifies a destination file for the combined fragments. Valid options: a string containing an absolute path. Default value: the title of your declared resource.

Default value: `namevar`.

##### `replace`

Data type: Boolean.

Specifies whether to overwrite the destination file if it already exists. Valid options: `true` and `false`.

Default value: `true`.

##### `tag`

Data type: String.

*Required.* Specifies a unique tag reference to collect all data_fragments with the same tag.

##### `validate_cmd`

Data type: String

Specifies a validation command to apply to the destination file. Requires Puppet version 3.5 or newer. Valid options: a string to be passed to a file resource. 

Default value: `undef`.

##### `format`

Data type: String

Specify what data type to merge the fragments as. Valid options: 'plain', 'yaml', 'json', 'json-pretty'.

Default value: `plain`.

##### `force`

Data type: Boolean

Specifies whether to merge data structures, keeping the values with higher order. Valid options: `true` and `false`.

Default value: `false`.

#### Type: `data_fragment`

##### `content`

Data type: String.

Supplies the content of the fragment. **Note**: You must supply either a `content` parameter or a `source` parameter. Valid options: a string. 

Default value: `undef`.

##### `order`

Data type: String, Integer.

Reorders your fragments within the destination file. Fragments that share the same order number are ordered by name. Valid options: a string (recommended) or an integer. 

Default value: '10'.

##### `source`

Data type: String.

Specifies a file to read into the content of the fragment. **Note**: You must supply either a `content` parameter or a `source` parameter. Valid options: a string or an array, containing one or more Puppet URLs. 

Default value: `undef`.

##### `tag`

Data type: String.

*Required.* Specifies a unique tag to be used by data_file to reference and collect content.

##### `target`

Data type: String.

*Required.* Specifies the destination file of the fragment. Valid options: a string containing the path or title of the parent `data_file` resource.
