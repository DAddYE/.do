namespace :l do
  desc 'clone a remote lipsiahosting --name=project_name'
  task :clone do |args|
    name = args[:name]
    unless name
      log "\e[31mYou must provide --name project_name!\e[0m"
      exit
    end

    if File.exist?('./%s' % name)
      log "\e[31mSorry, the %s already cloned\e[0m" % name
    end

    sh 'git clone git@lipsiasoft.biz:/%s.git' % name
  end

  desc 'setup a local repository for lipsiahosting'
  task :setup do
    name = File.basename(File.expand_path('.'))
    exit unless yes?('Do you want to setup "%s"?' % name)
    srv = nil

    until servers.map(&:name).include?(srv)
      srv = ask("Which server do you want to use (%s)" % servers.map(&:name).join(", ")).to_sym
    end

    if File.exist?('.git')
      exit unless yes?('Project "%s" has already a working repo, do you want remove it?' % name)
      run 'rm -rf .git'
    end

    run 'git init'
    run 'git remote add origin git@lipsiasoft.biz:/%s.git' % name
    run_task('l:commit') if yes?("Are you ready to commit it, database, config etc is correct?")
  end

  desc 'git add .; git commit -a; git push'
  task :commit do
    run 'git add .'
    run 'git commit -a'
    run 'git push origin master'
  end
end
