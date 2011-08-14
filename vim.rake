namespace :vim do
  desc 'install vim from sources with ruby, python and perl support'
  task :install do
    Dir.chdir('/tmp')
    run "rm -rf vim*"
    run "curl -O http://ftp.vim.org/pub/vim/unix/vim-7.3.tar.bz2"
    run "tar xvf vim-*"
    Dir.chdir('vim73')
    run "./configure --prefix=/usr --enable-perlinterp=yes --enable-pythoninterp=yes --enable-rubyinterp --enable-multibyte"
    run " make"
    run "sudo make install"
    run "rm -rf vim*"
  end

  desc 'update janus'
  task :update do
    run 'git clone git://github.com/DAddYE/vim.git ~/.vim' unless File.exist?(File.expand_path('~/.vim'))
    run 'cd ~/.vim && rake'
  end
end
