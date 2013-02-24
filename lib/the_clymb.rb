require 'adapter'
require 'json'
require 'resolv'

# Customizes the failover steps for The Clymb.
#
# Assumes that username is Unix user who can use sudo to manage the
# machines and master_cname is the DNS entry which points to the
# current master hostname via a DNS CNAME.
#
# We store a JSON file for each machine managed by Chef which has
# information like its public IP address, the set of roles it fulfills,
# etc.  Using this repository, we can lookup the set of Redis slaves
# and take actions on them.
class TheClymb < Adapter
  attr_accessor :username, :master_cname

  def initialize
    self.username = 'deploy'
    self.master_cname = 'redis.prd.theclymb.com'
  end

  def shutdown_old_instance
    puts "- Ensure that the old master is no longer available."
    puts "Would you like me to try to shut it down?"
    if yes
      cmd("ssh #{username}@#{master_cname} 'sudo /etc/init.d/redis_server stop'")
    else
      puts "Please log into #{master_cname} and run 'sudo /etc/init.d/redis_server stop'"
    end
    pause
  end

  def update_dns
    puts "- Change #{master_cname} to point to #{newmaster}."
    if yes
      require 'dynect_rest'
      dyn = DynectRest.new(*DYNECT_CREDS)
      dyn.cname.fqdn(master_cname).cname(newmaster).ttl(60).save(true)
      dyn.publish
    else
      puts "Please log into Dynect and change the CNAME for #{master_cname}."
      puts "https://manage.dynect.com"
    end
    pause
  end

  def confirm_server
    begin
      puts "Please tell me the new Redis master hostname, e.g. 'app-2.production.acmecorp.com':"
      self.newmaster = $stdin.gets.strip
      newip = Resolv.getaddress(newmaster)
      puts "Thank you, the new server was found at #{newip}"
    rescue => ex
      puts "#{ex.class.name}: #{ex.message}"
      exit(1)
    end
  end

  def promote_new_master
    puts "- Promote the chosen Redis instance to the master role"
    cmd "ssh #{username}@#{newmaster} 'redis-cli slaveof no one'"
    puts "NOTE: you should log into #{newmaster} and edit /etc/redis/redis.conf to remove the slaveof line ASAP"
  end

  def restart_slaves
    puts "- Restart the other slaves so they start replicating from the new master"
    slaves.each do |fqdn|
      next if fqdn.downcase == newmaster.downcase
      cmd "ssh #{username}@#{fqdn} 'sudo /etc/init.d/redis_server restart'"
    end
  end

  def restart_services
    apps.each do |fqdn|
      puts "- Restart application services on #{fqdn}"
      cmd "ssh #{username}@#{fqdn} 'sudo restart workers'"
      cmd "ssh #{username}@#{fqdn} 'sudo restart unicorn'"
    end
  end

  private

  def slaves
    nodes('redis_slave')
  end

  def apps
    nodes('app')
  end

  def nodes(role)
    all_nodes = Dir['nodes/*.json'].map do |filename|
      JSON.parse(File.read(filename))
    end
    all_nodes.select { |data|
      data['chef_environment'] == 'production' &&
      data['run_list'].any? {|x| x =~ /\Arole\[#{role}\]\z/ }
    }.map { |data| data['fqdn'] }
  end
end
