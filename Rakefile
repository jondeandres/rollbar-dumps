require 'rake'
require "bundler/gem_tasks"

TT_SRC = File.join('lib', 'rollbar', 'dumps', 'gdb_response.treetop')
TT_DST = File.join('lib', 'rollbar', 'dumps', 'gdb_response_parser.rb')

desc 'Generate treetop parser grammar'
task :grammar do
  if (!File.exists?( TT_DST)) ||
    ( File.mtime( TT_SRC ) > File.mtime( TT_DST ) )
    puts "Building treetop grammar #{TT_SRC} -> #{TT_DST}"

    puts system('bundle exec tt', '-o', TT_DST, TT_SRC )
  end
end
