Vagrant.configure("2") do |config|
  config.vm.hostname = "#{`hostname`[0..-2]}-eirini"
  config.ssh.forward_agent = true

  config.vm.provision "shell", path: "provision.sh"
  config.vm.provision "shell" do |p|
    p.path = "provision-user.sh"
    p.privileged = false
  end

  home = ENV['HOME']
  config.vm.provider "virtualbox" do |vb, override|
    vb.name = 'eirini-station'
    vb.memory = ENV.fetch('EIRINI_STATION_MEMORY', '8192').to_i
    vb.cpus = ENV.fetch('EIRINI_STATION_CPUS', '4').to_i

    # workaround for slow boot (https://bugs.launchpad.net/cloud-images/+bug/1829625)
    vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
    vb.customize ["modifyvm", :id, "--uartmode1", "file", "./ttyS0.log"]

    override.disksize.size = '50GB'

    override.vm.box = "ubuntu/focal64"

    override.vm.synced_folder "~/.ngrok2", "/home/vagrant/.ngrok2"

    override.vm.network "public_network", bridge: [
      "en0: Wi-Fi (AirPort)",
      "en0: Wi-Fi (Wireless)",
    ]

    override.ssh.extra_args = ["-R", "/home/vagrant/.gnupg/S.gpg-agent-host:#{home}/.gnupg/S.gpg-agent"]

  end

  config.vm.provider "vmware_desktop" do |vmw, override|
    vmw.vmx["displayname"] = 'eirini-station'
    vmw.memory = ENV.fetch('EIRINI_STATION_MEMORY', '8192').to_i
    vmw.cpus = ENV.fetch('EIRINI_STATION_CPUS', '4').to_i

    override.vm.box = "bento/ubuntu-20.04"

    override.vm.synced_folder "~/.ngrok2", "/home/vagrant/.ngrok2"

    override.vm.network "public_network", bridge: [
      "en0: Wi-Fi (AirPort)",
      "en0: Wi-Fi (Wireless)",
    ]

    override.ssh.extra_args = ["-R", "/home/vagrant/.gnupg/S.gpg-agent-host:#{home}/.gnupg/S.gpg-agent"]
  end
end



class SetHostTimezonePlugin < Vagrant.plugin('2')
  class SetHostTimezoneAction
    def initialize(app, env)
      @app = app
    end

    def call(env)
      @app.call(env)

      machine = env[:machine]

      if machine.guest.capability?(:change_timezone)
        timezone =`cat /etc/timezone 2>/dev/null`.strip
        if $?.exitstatus != 0
          timezone = nil
          if Vagrant::Util::Platform.darwin?
            puts "🙄 It looks like you are a Mac user, let me try to figure your timezone out...."
            timezone=`realpath --relative-to=/var/db/timezone/zoneinfo $(readlink /etc/localtime)`.strip

            if $?.exitstatus != 0
              puts "🤬 I might need to sudo to get your timezone, can you believe that!?"
              timezone =`sudo systemsetup -gettimezone | awk '{ print $3 }'`.strip
            end
          end

          if timezone.nil? || timezone.empty?
            # Thanks to https://stackoverflow.com/a/46778032
            puts "🙁 Alas, human, I did my best to figure out your timezone, but I failed!\nFalling back to timezone offset...\n"
            offset = ((Time.zone_offset(Time.now.zone) / 60) / 60)
            timezone_suffix = offset >= 0 ? "-#{offset.to_s}" : "+#{offset.to_s}"
            timezone = 'Etc/GMT' + timezone_suffix
          end
        end
        puts "🌐 Setting timezone to " + timezone + "...\n"
        machine.guest.capability(:change_timezone, timezone)
      else
        puts "🤔 Hmmmm, it seems the guest VM does not support the change_timezone capability..."
      end

    end
  end

  name 'set-host-timezone'

  action_hook 'set-host-timezone' do |hook|
    hook.before Vagrant::Action::Builtin::Provision, SetHostTimezoneAction
  end
end
