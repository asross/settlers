# Settlers

## Setup

`gem install bundler`
`bundle install`
`ruby webapp.rb` or `ruby textbased.rb`

## Spec

* `models/` directory contains abstract logic for playing catan.
* `webapp.rb` exposes that logic through a web interface
* `views/` directory contains the HTML/javascript/CSS required for the web interface
* `textbased.rb` exposes Catan logic through a text-based interface
* `test/` directory contains tests that run with a gem called [minitest](https://github.com/seattlerb/minitest)
* `test/unit/` directory contains unit tests for models
* `test/webapp/` directory contains integration tests for the web app
* `test/textbased/` directory contains integration tests for the text-based interface
