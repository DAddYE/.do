namespace :remote do

  namespace :vim do
    desc 'Install a VIM from sources'
    task :install, :in => :remote do
      run 'yum install hg -y' if run('which hg').chomp == ''
      run 'hg clone https://code.google.com/p/vim'
      run 'cd vim &&',
          './configure',
          '--enable-gui=no',
          '--without-x',
          '--disable-nls',
          '--enable-multibyte',
          '--with-tlib=ncurses',
          '--enable-pythoninterp',
          '--enable-rubyinterp',
          '--with-ruby-command=/usr/bin/ruby',
          '--with-features=huge'
      run 'cd tmp/vim && make && make install'
      run 'rm -rf vim'
    end # install
  end # vim
end # remote
