# This file is used to setup RedHat based distribution, like Amazon, Centos or Fedora
namespace :remote do

  desc "configure a new server"
  task :conf => [:bash, :ruby_env, :motd, :hostname, :sudoers, :timesync, :gemrc, :yum]

  namespace :conf do
    desc "add pretty colors to you bash shell"
    task :bash, :in => :remote do
      tpl = <<-TXT.gsub(/^ {6}/, '')
        # Source global definitions
        if [ -f /etc/bashrc ]; then
          . /etc/bashrc
        fi

        # Colors
        export PS1='\\[\\033[01;31m\\]\\u\\[\\033[01;33m\\]@\\[\\033[01;36m\\]\\h \\[\\033[01;33m\\]\\w \\[\\033[01;35m\\]\\$ \\[\\033[00m\\]'
        export LS_OPTIONS="--human --color=always"
      TXT
      run "touch /root/.bashrc"
      replace :all, tpl, "/root/.bashrc"
    end

    desc "don't permit root logins"
    task :sshd, :in => :remote do
      replace(/^#PermitRootLogin yes/, "PermitRootLogin without-password", "/etc/ssh/sshd_config")
      run "service sshd reload"
    end

    desc "upgrade rubygems and install useful gems"
    task :gems => :ree, :in => :remote do
      run "gem update --system" if yes?("Do you want to update rubygems?")
      run "gem install rake"
      run "gem install highline"
      run "gem install bundler"
      run "ln -s /opt/ruby-enterprise/bin/bundle /usr/bin/bundle" unless exist?("/usr/bin/bundle")
    end

    desc "install image magick checking the best choice for your env"
    task :imagemagick, :in => :remote do
      run "yum install libjpeg-devel libpng-devel glib2-devel fontconfig-devel zlib-devel ghostscript-fonts libwmf-devel freetype-devel libtiff-devel -y"
      run "wget ftp://ftp.imagemagick.org/pub/ImageMagick/ImageMagick.tar.gz"
      run "tar zxzvf ImageMagick.tar.gz"
      run "cd ImageMagick* && ./configure && make && make install && cd .."
      run "rm -rf ImageMagick*"
      %w[stream montage mongrify import identify display convert conjure composite compare animate].each do |bin|
        run 'rm -rf /usr/bin/%s' % bin
        run 'ln -s /usr/local/bin/%s /usr/bin/%s' % [bin, bin]
      end
      run "ldconfig /usr/local/lib"
      run 'touch /var/spool/cron/root' unless exist?('/var/spool/cron/root')
      append "@reboot ldconfig /usr/local/lib", '/var/spool/cron/root'
    end

    desc "create motd for each server"
    task :motd, :in => :remote do
      replace :all, "Hey boss! Welcome to the \e[1m#{name}\e[0m of LipsiaSOFT s.r.l.\n", "/etc/motd"
    end

    desc "we need a decent hostname"
    task :hostname, :in => :remote do
      replace(/HOSTNAME=.*/, "HOSTNAME=#{host}", "/etc/sysconfig/network")
    end

    desc "redirect emails to a real account"
    task :root_emails, :in => :remote do
      append "\nroot: servers@lipsiasoft.com", "/etc/aliases"
      run "newaliases"
    end

    desc "configure time sync with ntp"
    task :timesync, :in => :remote do
      run "yum install ntp -y"
      run "chkconfig --levels 2345 ntpd on"
      run "service ntpd stop"
      run "yes | cp -r /usr/share/zoneinfo/Europe/Rome /etc/localtime"
      run "ntpdate europe.pool.ntp.org"
      run "service ntpd start"
    end

    desc "remove titty for sudoers"
    task :sudoers, :in => :remote do
      run "chmod +w /etc/sudoers"
      replace(/^Defaults    requiretty/, "# Defaults    requiretty", "/etc/sudoers")
      run "chmod -w /etc/sudoers"
    end

    desc "don't install 32bit stuff if we are on a 64 release"
    task :yum_i686, :in => :remote do
      arch = run("arch", :silent => true)
      if arch == "x86_64"
        gsub "[main]", "[main]\nexclude=*.i386 *.i586 *.i686", "/etc/yum.conf"
        run "yum remove *.{i386,i586,i686} -y"
      else
        puts "your server is a 32-bit so isn't necessary exclude i386 yum packages"
      end
    end

    desc "perform clean and update"
    task :yum_fresh, :in => :remote do
      run "yum clean all -y"
      run "yum update -y"
    end

    desc "yum base configuration, epel, gcc sendmail, curl make, mysql ..."
    task :yum => [:yum_fresh, :yum_i686], :in => :remote do
      run "rpm -Uvh http://download.fedora.redhat.com/pub/epel/5/i386/epel-release-5-4.noarch.rpm"
      run "yum install sudo gcc gcc-c++ sendmail curl-devel vixie-cron make patch apr apr-devel apr-util-devel byacc mysql-server mysql mysql-devel git java java-1.6.0-openjdk-devel libxml2-devel libxslt-devel autoconf python26 -y"
      run "chkconfig --level 2345 sendmail on"
      run "chkconfig --level 2345 mysqld on"
      run "service sendmail restart"
      run "service mysqld restart"
      pwd = ask "Tell me the password for mysql"
      run "mysqladmin -u root -p password '#{pwd}'", :input => "\n"
      run "service mysqld restart"
      run "ln -fs /var/lib/mysql/mysql.sock /tmp/mysql.sock"
    end

    desc "install latest ruby enterprise"
    task :ree, :in => :remote do
      version = "2011.03"
      match = run("ruby -v", :silent => true) =~ /Ruby Enterprise Edition (\d{4}\.\d{2})/
      if !match || (match && yes?("Detected ree '#{$1}' latest is '#{version}' do you want to proceed ?"))
        # Get latest from here http://rubyforge.org/frs/?group_id=5833
        run "yum install ruby readline-devel -y"
        run "rm -rf ruby-enterprise-*"
        run "wget http://rubyenterpriseedition.googlecode.com/files/ruby-enterprise-1.8.7-2011.03.tar.gz"
        run "tar zxvf ruby-enterprise-* && cd ruby-enterprise-* && ./installer --auto /opt/ruby-enterprise && cd .."
        run "rm -rf ruby-enterprise-*"
        run "yum remove ruby -y"
        run "ln -fs /opt/ruby-enterprise/bin/gem /usr/bin/gem"
        run "ln -fs /opt/ruby-enterprise/bin/irb /usr/bin/irb"
        run "ln -fs /opt/ruby-enterprise/bin/rake /usr/bin/rake"
        run "ln -fs /opt/ruby-enterprise/bin/ruby /usr/bin/ruby"
      end
    end

    desc "configure .gemrc to does not install ri and rdoc"
    task :gemrc, :in => :remote do
      tpl = <<-TPL.gsub(/^ {6}/, "")
        ---
        gem: -n/opt/ruby-enterprise/bin --no-ri --no-rdoc
      TPL
      run "touch /root/.gemrc"
      replace :all, tpl, "/root/.gemrc"
    end

    desc "setup logwatch"
    task :logwatch, :in => :remote do
      run "yum install logwatch -y"
      replace(/MailFrom =.*/, "MailFrom = logs", "/usr/share/logwatch/default.conf/logwatch.conf")
      replace(/Range =.*/, "Range = yesterday", "/usr/share/logwatch/default.conf/logwatch.conf")
      replace(/Detail =.*/, "Detail = High", "/usr/share/logwatch/default.conf/logwatch.conf")
      run "logwatch --detail High --range Today"
    end

    desc "setup logrotate for /mnt/www/apps/*/log/*.log"
    task :logrotate, :in => :remote do
      tpl = <<-TPL.gsub(/^ {6}/, "")
        /mnt/www/apps/*/log/*.log {
          daily
          missingok
          rotate 7
          compress
          delaycompress
          notifempty
          copytruncate
        }
      TPL
      run "yum install logrotate -y"
      run "touch /etc/logrotate.d/rails"
      replace :all, tpl, "/etc/logrotate.d/rails"
    end

    desc "setup crontab for project removing from tmp session stuff"
    task :projects_crontab, :in => :remote do
      tpl = <<-TPL.gsub(/^ {6}/, "")
        find /tmp/ -name "ruby_sess*" -cmin +60 -exec rm -rf {} \\;
        find /tmp/ -name "open-uri*" -cmin +60 -exec rm -rf {} \\;
        find /tmp/ -name "CGI*" -cmin +600 -exec rm -rf {} \\;
        find /tmp/ -name "stream*" -cmin +600 -exec rm -rf {} \\;
        find /tmp/ -name "RackMultipart*" -cmin +600 -exec rm -rf {} \\;
        find /tmp/ -name "passenger*" -cmin +600 -exec rm -rf {} \\;
        find /tmp/ -name "mini_magick*" -cmin +600 -exec rm -rf {} \\;
      TPL
      run "rm -rf /etc/cron.hourly/cleaner"
      replace :all, tpl, "/etc/cron.hourly/cleaner"
      run "chmod +x /etc/cron.hourly/cleaner"
      run "service crond restart"
    end

    desc "configure RACK, RAILS, PADRINO ENV = production"
    task :ruby_env, :in => :remote do
      replace 'export RAILS_ENV="production"export RACK_ENV="production"export PADRINO_ENV="production"', '', '/root/.bash_profile'
      append 'export RAILS_ENV="production"', '/root/.bash_profile'
      append 'export RACK_ENV="production"', '/root/.bash_profile'
      append 'export PADRINO_ENV="production"', '/root/.bash_profile'
    end
  end
end
