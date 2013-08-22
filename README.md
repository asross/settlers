# Settlers

of Catan!

## Setup

1. `gem install bundler`
2. `bundle install`
3. `ruby webapp.rb` or `ruby textbased.rb`
4. If you run into problems, ensure you have Ruby 1.9 installed (check with `ruby --version`)

## Setbacks

A lot of this code is very old.

## Settings

* `models/` directory contains abstract logic for playing catan.
* `webapp.rb` exposes that logic through a web interface
* `textbased.rb` exposes the logic through a text-based interface
* `views/` directory contains the HTML/javascript/CSS required for the web interface
* `test/` directory contains tests that run with a gem called [minitest](https://github.com/seattlerb/minitest)
* `test/unit/` directory contains unit tests for models
* `test/webapp/` directory contains integration tests for the web app
* `test/textbased/` directory contains integration tests for the text-based interface
