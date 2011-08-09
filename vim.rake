namespace :vim do
  desc "install vim with python and ruby support"
  task :install do
    run "rm -rf vim*"
    run "yum install bzip2 -y" unless exist?('/usr/bin/bzip2')
    run "wget http://ftp.vim.org/pub/vim/unix/vim-7.3.tar.bz2"
    run "tar xvf vim-*"
    run "cd vim73",
        "&& ./configure --prefix=/usr --enable-perlinterp=no --enable-pythoninterp=yes --enable-rubyinterp --enable-multibyte",
        "&& make",
        "&& make install"
    run "rm -rf vim*"
  end

  desc "configure with a janus custom template"
  task :configure => ['configure:gems'] do
    run "yum install vim git -y" unless exist?('/usr/bin/git')
    run "rm -rf ~/.vim" unless exist?('/usr/bin/git')
    run "git clone git://github.com/DAddYE/vim.git ~/.vim"
    run "cd ~/.vim && rake"
  end
end
