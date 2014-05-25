# Requiring all the _test.rb files will automatically run any tests they contain.

if ARGV[0]
  Dir.glob(File.join('.', ARGV[0], '*_test.rb')).each { |f| require f }
else
  Dir.glob('./test/**/*_test.rb').each { |f| require f }
end
