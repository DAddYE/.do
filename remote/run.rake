namespace :remote do
  desc 'Executes arbitrary commands on remote servers'
  task :run, :in => :remote do
    args = ARGV.dup[1..-1]
    args.reject! { |a| remote.any? { |s_name| a.include?(s_name.to_s) } }
    run args
  end # run
end # remote
