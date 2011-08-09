namespace :l do
  local :setup do
    name = File.basename(File.expand_path('.'))
    exit unless yes?('Do you want to setup "%s"?' % name)
    srv = nil

    until servers.map(&:name).include?(srv)
      srv = ask("Which server do you want to use (%s)" % servers.map(&:name).join(", ")).to_sym
    end

    if File.exist?('.git') 
      exit unless yes?('Project "%s" has already a working repo, do you want remove it?' % name)
      sh 'rm -rf .git'
    end

    sh 'git init'
    sh 'git remote add origin git@lipsiasoft.biz:/%s.git' % name
    Rake::Task['l:commit'].invoke if yes?("Are you ready to commit it, database, config etc is correct?")
  end

  local :commit do
    sh 'git add .'
    sh 'git commit -a'
    sh 'git push origin master'
  end
end
