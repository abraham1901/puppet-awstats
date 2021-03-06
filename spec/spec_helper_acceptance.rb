require 'beaker-rspec/spec_helper'
require 'beaker-rspec/helpers/serverspec'

unless ENV['RS_PROVISION'] == 'no' or ENV['BEAKER_provision'] == 'no'
  # This will install the latest available package on el and deb based
  # systems fail on windows and osx, and install via gem on other *nixes
  foss_opts = {:default_action => 'gem_install'}

  if default.is_pe?; then
    install_pe;
  else
    install_puppet(foss_opts);
  end

  hosts.each do |host|
    on hosts, "mkdir -p #{host['distmoduledir']}"
  end
end

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module and dependencies
    hosts.each do |host|
      on host, "mkdir -p #{host['distmoduledir']}/awstats"
      result = on host, "echo #{host['distmoduledir']}/awstats"
      target = result.raw_output.chomp

      %w(files lib manifests templates metadata.json).each do |file|
        scp_to host, "#{proj_root}/#{file}", target
      end
      on host, puppet('module', 'install', 'puppetlabs-stdlib'), {:acceptable_exit_codes => [0, 1]}
      on host, puppet('module', 'install', 'stahnma-epel'), {:acceptable_exit_codes => [0, 1]}
      on host, puppet('module', 'install', 'puppetlabs-apache'), {:acceptable_exit_codes => [0, 1]}
    end
  end
end
