require 'bundler/gem_tasks'
require 'pathname'

ROOT = Pathname.new(__FILE__).dirname.expand_path

begin
  require 'rubocop/rake_task'
  desc 'Runs rubocop with our custom settings'
  RuboCop::RakeTask.new(:rubocop) do |task|
    config = ROOT.join('.rubocop').to_s
    task.options = ['-D', '-c', config]
  end
rescue LoadError
  puts 'Not loading rubocop tasks ...'
end

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new do |task|
    test_dir = ROOT.join('test')

    task.rspec_opts = [
      "-I#{test_dir}",
      "-I#{test_dir}/spec",
      '--color',
      '--format doc'
    ]
    task.verbose = false
  end
  task default: :spec
rescue LoadError
  puts 'No RSPEC for you!'
end
