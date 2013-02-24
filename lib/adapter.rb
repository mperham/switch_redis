begin
  require 'credentials'
rescue LoadError
  puts "No secret credentials loaded"
end

class Adapter

  attr_accessor :newmaster

  # Main method to execute the failover steps.
  # You don't override this.
  def run
    welcome
    confirm_server
    shutdown_old_instance
    update_dns
    promote_new_master
    restart_slaves
    restart_services
    complete
  end

  def shutdown_old_instance
    raise NotImplementedError
  end

  def update_dns
    raise NotImplementedError
  end

  def promote_new_master
    raise NotImplementedError
  end

  def restart_slaves
    raise NotImplementedError
  end

  def restart_services
    raise NotImplementedError
  end

  def welcome
    puts "### DRY RUN MODE ACTIVE ###" if dryrun?
    puts "#" * 80
    puts
    puts "Welcome to the Redis failover script."
    puts
  end

  def complete
    puts "Failover process is complete."
    puts "NOTE: You still have some manual work that can be done later:"
    puts "  1) Update the Chef roles in nodes/app* to reflect the new master and slaves"
    puts "  2) Roll out the changes to production to ensure redis.conf is up-to-date on all machines"
  end

  private

  def cmd(command)
    puts "About to run command: #{command}"
    pause
    system(command) unless dryrun?
  end

  def yes
    puts "Press 'y' if you want me to do that for you now."
    !dryrun? && $stdin.gets.strip.downcase == 'y'
  end

  def pause
    puts " >>>>>>>> Paused, press a key to continue"
    $stdin.gets
  end

  def dryrun?
    ARGV[0] == '-n'
  end
end
