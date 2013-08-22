# Requiring all the _test.rb files will automatically run any tests they contain.
Dir.glob('./test/**/*_test.rb').each { |f| require f }
