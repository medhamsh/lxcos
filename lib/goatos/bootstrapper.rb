require 'chef/knife/ssh'
require 'chef/knife/bootstrap'
require 'chef/knife/cookbook_upload'
require 'chef_zero/server'
require 'socket'

Chef::Knife::Ssh.load_deps
Chef::Knife::Bootstrap.load_deps
Chef::Knife::CookbookUpload.load_deps

module GoatOS
  class Bootstrapper
    def initialize(host, config)
      @host = host
      @config = config
      @server = ChefZero::Server.new(host: host_ip)
    end

    def bootstrap
      Dir.mktmpdir do |dir|
        start_chef_zero
        configure_chef(dir)
        upload_cookbooks
        knife_bootstrap
        node_set('recipe[goatos::configure]')
        invoke_chef_run
        stop_chef_zero
      end
    end

    def node_set(*items)
      node = Chef::Node.load(@config[:name])
      node.run_list.reset!
      items.each do |item|
        node.run_list << item
      end
      node.save
    end

    def upload_cookbooks
      plugin = Chef::Knife::CookbookUpload.new
      plugin.config[:all] = true
      plugin.config[:cookbook_path] = [ File.expand_path('../../../cookbooks', __FILE__) ]
      plugin.run
    end

    def start_chef_zero
      @server.start_background unless @server.running?
    end

    def configure_chef(dir)
      key, _ =@server.gen_key_pair
      path = File.join(dir, 'client.pem')
      File.open(path, 'w') do |f|
        f.write(key)
      end
      Chef::Config[:chef_server_url] = 'http://' + host_ip + ':8889'
      Chef::Config[:node_name] = 'admin'
      Chef::Config[:client_key] = path
      Chef::Config[:validation_key] = path
    end

    def stop_chef_zero
      @server.stop if @server.running?
    end

    def knife_bootstrap
      plugin = Chef::Knife::Bootstrap.new
      plugin.name_args = [ @host ]
      plugin.config[:ssh_user] = @config[:ssh_user]
      plugin.config[:ssh_password] = @config[:ssh_password]
      plugin.config[:chef_node_name] = @config[:name]
      plugin.config[:use_sudo] = true
      plugin.config[:use_sudo_password] = true
      plugin.config[:run_list] = ['recipe[goatos::install]']
      plugin.config[:distro] = 'chef-full'
      plugin.config[:host_key_verify] = false
      plugin.run
    end

    def invoke_chef_run
      ssh = Chef::Knife::Ssh.new
      command =  "echo '#{@config[:ssh_password]}' | sudo -S chef-client"
      ssh.name_args = [ @host , command ]
      ssh.config[:ssh_user] = @config[:ssh_user]
      ssh.config[:ssh_password] = @config[:ssh_password]
      ssh.config[:manual] = true
      ssh.config[:host_key_verify] = false
      ssh.config[:on_error] = :raise
      ssh.run
    end

    private

    def host_ip
      @host_ip ||= UDPSocket.open do |s|
        s.connect '8.8.8.8', 1
        s.addr.last
      end
    end
  end
end
