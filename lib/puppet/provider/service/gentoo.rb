# Manage gentoo services.  Start/stop is the same as InitSvc, but enable/disable
# is special.
Puppet::Type.type(:service).provide :gentoo, :parent => :init do
  desc <<-EOT
    Gentoo's form of `init`-style service management.

    Uses `rc-update` for service enabling and disabling.

  EOT

  commands :update => "/sbin/rc-update"

  confine :operatingsystem => :gentoo

  defaultfor :operatingsystem => :gentoo

  def self.defpath
    superclass.defpath
  end

  def self.instances
    # this exclude list was found with grep -L '\/sbin\/runscript' /etc/init.d/*
    self.get_services(self.defpath, ['functions.sh', 'reboot.sh', 'shutdown.sh'])
  end

  def disable
      output = update :del, @resource[:name], :default
  rescue Puppet::ExecutionFailure
      raise Puppet::Error, "Could not disable #{self.name}: #{output}"
  end

  def enabled?
    begin
      output = update :show
    rescue Puppet::ExecutionFailure
      return :false
    end

    line = output.split(/\n/).find { |l| l.include?(@resource[:name]) }

    return :false unless line

    # If it's enabled then it will print output showing service | runlevel
    if output =~ /^\s*#{@resource[:name]}\s*\|\s*(boot|default)/
      return :true
    else
      return :false
    end
  end

  def enable
      output = update :add, @resource[:name], :default
  rescue Puppet::ExecutionFailure
      raise Puppet::Error, "Could not enable #{self.name}: #{output}"
  end
end
