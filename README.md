# Settlers

of Catan!

## Setup

1. `gem install bundler`
2. `bundle install`
3. `ruby webapp.rb` or `ruby textbased.rb`

## Setbacks

I wrote most of this code before I had learned anything about Ruby.

## Settings

* `models/` directory contains abstract logic for playing catan.
* `webapp.rb` exposes that logic through a web interface
* `textbased.rb` exposes the logic through a text-based interface
* `views/` directory contains the HTML/javascript/CSS required for the web interface
* `test/` directory contains tests that run with a gem called [minitest](https://github.com/seattlerb/minitest)
* `test/unit/` directory contains unit tests for models
* `test/webapp/` directory contains integration tests for the web app
* `test/textbased/` directory contains integration tests for the text-based interface
