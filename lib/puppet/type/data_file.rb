require 'puppet/type/file/owner'
require 'puppet/type/file/group'
require 'puppet/type/file/mode'
require 'puppet/util/checksums'

Puppet::Type.newtype(:data_file) do
  @doc = "Gets all the file fragments and puts these into the target file.
    This will mostly be used with exported resources.

    example:
      Data_fragment <<| tag == 'unique_tag' |>>

      data_file { '/tmp/file':
        tag            => 'unique_tag', # Mandatory
        path           => '/tmp/file',  # Optional. If given it overrides the resource name
        owner          => 'root',       # Optional. Default to undef
        group          => 'root',       # Optional. Default to undef
        mode           => '0644'        # Optional. Default to undef
        order          => 'numeric'     # Optional, Default to 'numeric'
        ensure_newline => false         # Optional, Defaults to false
      }
  "

  ensurable do
    defaultvalues

    defaultto { :present }
  end

  def exists?
    self[:ensure] == :present
  end

  newparam(:tag) do
    desc "Tag reference to collect all data_fragment's with the same tag"
  end

  newparam(:path, :namevar => true) do
    desc "The output file"

    validate do |value|
      unless (Puppet::Util.absolute_path?(value, :posix) or Puppet::Util.absolute_path?(value, :windows))
        raise ArgumentError, "File paths must be fully qualified, not '#{value}'"
      end
    end
  end

  newparam(:owner, :parent => Puppet::Type::File::Owner) do
    desc "Desired file owner."
  end

  newparam(:group, :parent => Puppet::Type::File::Group) do
    desc "Desired file group."
  end

  newparam(:mode, :parent => Puppet::Type::File::Mode) do
    desc "Desired file mode."
  end

  newparam(:order) do
    desc "Controls the ordering of fragments. Can be set to alpha or numeric."

    newvalues(:alpha, :numeric)

    defaultto :numeric
  end

  newparam(:backup) do
    desc "Controls the filebucketing behavior of the final file and see File type reference for its use."
    defaultto 'puppet'
  end

  newparam(:replace, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc "Whether to replace a file that already exists on the local system."
    defaultto :true
  end

  newparam(:validate_cmd) do
    desc "Validates file."
  end

  newparam(:ensure_newline, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc "Whether to ensure there is a newline after each fragment."
    defaultto :false
  end

  newparam(:format) do
    desc "What data type to merge the fragments as."

    newvalues(:plain, :yaml, :json, :'json-pretty')

    defaultto :plain
  end

  newparam(:force, :boolean => true, :parent => Puppet::Parameter::Boolean) do
    desc "Forcibly merge duplicate keys keeping values of the highest order."

    defaultto :false
  end

  # Inherit File parameters
  newparam(:selinux_ignore_defaults) do
  end

  newparam(:selrange) do
  end

  newparam(:selrole) do
  end

  newparam(:seltype) do
  end

  newparam(:seluser) do
  end

  newparam(:show_diff) do
  end
  # End file parameters

  # Autorequire the file we are generating below
  autorequire(:file) do
    [self[:path]]
  end

  def should_content
    return @generated_content if @generated_content
    @generated_content = ""
    content_fragments = []

    resources = catalog.resources.select do |r|
      r.is_a?(Puppet::Type.type(:data_fragment)) && r[:tag] == self[:tag]
    end

    resources.each do |r|
      content_fragments << ["#{r[:order]}___#{r[:name]}", fragment_content(r)]
    end

    if self[:order] == :numeric
      sorted = content_fragments.sort do |a, b|
        def decompound(d)
          d.split('___', 2).map { |v| v =~ /^\d+$/ ? v.to_i : v }
        end

        decompound(a[0]) <=> decompound(b[0])
      end
    else
      sorted = content_fragments.sort_by do |a|
        a_order, a_name = a[0].split('__', 2)
        [a_order, a_name]
      end
    end

    case self[:format]
    when :plain
      @generated_content = sorted.map { |cf| cf[1] }.join
    when :yaml
      content_array = sorted.map do |cf|
        YAML.load(cf[1])
      end
      content_hash = content_array.reduce({}) do |memo, current|
        nested_merge(memo, current)
      end
      @generated_content = content_hash.to_yaml
    when :json
      content_array = sorted.map do |cf|
        JSON.parse(cf[1])
      end
      content_hash = content_array.reduce({}) do |memo, current|
        nested_merge(memo, current)
      end
      # Convert Hash
      @generated_content = content_hash.to_json
    when :'json-pretty'
      content_array = sorted.map do |cf|
        JSON.parse(cf[1])
      end
      content_hash = content_array.reduce({}) do |memo, current|
        nested_merge(memo, current)
      end
      @generated_content = JSON.pretty_generate(content_hash)
    end

    @generated_content
  end

  def nested_merge(hash1, hash2)
    # Deep-merge Hashes; higher order value is kept
    hash1.merge(hash2) do |k, v1, v2|
      if v1.is_a?(Hash) and v2.is_a?(Hash)
        nested_merge(v1, v2)
      elsif v1.is_a?(Array) and v2.is_a?(Array)
        (v1+v2).uniq
      else
        # Fail if there are duplicate keys without force
        unless v1 == v2
          unless self[:force]
            err_message = [
              "Duplicate key '#{k}' found with values '#{v1}' and #{v2}'.",
              'Use \'force\' attribute to merge keys.',
            ]
            fail(err_message.join(' '))
          end
          Puppet.debug("Key '#{k}': replacing '#{v2}' with '#{v1}'.")
        end
        v1
      end
    end
  end

  def fragment_content(r)
    if r[:content].nil? == false
      fragment_content = r[:content]
    elsif r[:source].nil? == false
      @source = nil
      Array(r[:source]).each do |source|
        if Puppet::FileServing::Metadata.indirection.find(source)
          @source = source 
          break
        end
      end
      self.fail "Could not retrieve source(s) #{r[:source].join(", ")}" unless @source
      tmp = Puppet::FileServing::Content.indirection.find(@source)
      fragment_content = tmp.content unless tmp.nil?
    end

    if self[:ensure_newline]
      fragment_content<<"\n" unless fragment_content =~ /\n$/
    end

    fragment_content
  end

  def generate
    file_opts = {
      :ensure => self[:ensure] == :absent ? :absent : :file,
    }

    [:path,
     :owner,
     :group,
     :mode,
     :replace,
     :backup,
     :selinux_ignore_defaults,
     :selrange,
     :selrole,
     :seltype,
     :seluser,
     :validate_cmd,
     :show_diff].each do |param|
      unless self[param].nil?
        file_opts[param] = self[param]
      end
    end

    metaparams = Puppet::Type.metaparams
    excluded_metaparams = [ :before, :notify, :require, :subscribe, :tag ]

    metaparams.reject! { |param| excluded_metaparams.include? param }

    metaparams.each do |metaparam|
      file_opts[metaparam] = self[metaparam] if self[metaparam]
    end

    [Puppet::Type.type(:file).new(file_opts)]
  end

  def eval_generate
    content = should_content

    if !content.nil? and !content.empty?
      catalog.resource("File[#{self[:path]}]")[:content] = content
    end

    [ catalog.resource("File[#{self[:path]}]") ]
  end
end
