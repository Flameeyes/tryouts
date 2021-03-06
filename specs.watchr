# Run me with:
#
#   $ watchr specs.watchr

# --------------------------------------------------
# Helpers
# --------------------------------------------------
def run(cmd)
  puts(cmd)
  system(cmd)
end

def run_all_tests
  # see Rakefile for the definition of the test:all task
  system( "rake -s test:all VERBOSE=true" )
end

# --------------------------------------------------
# Watchr Rules
# --------------------------------------------------
watch( '^test/test_.*\.rb' )  { |m| run( "ruby -rubygems -Ilib %s"              % m[0] ) }
watch( '^lib/(.*)\.rb'     )  { |m| run( "ruby -rubygems -Ilib test/test_%s.rb" % m[1] ) }

# --------------------------------------------------
# Signal Handling
# --------------------------------------------------
# Ctrl-\
Signal.trap('QUIT') do
  puts " --- Running all tests ---\n\n"
  run_all_tests
end

# Ctrl-C
Signal.trap('INT') { abort("\n") }

