# Requiring all the _test.rb files will automatically run any tests they contain.
Dir.glob(File.join('.', ARGV[0]||"test/**", '*_test.rb')).each { |f| require f }
