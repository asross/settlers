# Settlers

of Catan!

# Summary

Play Settlers of Catan on your home computer with your friends by running the server on one machine and having others connect to it either through a web or text interface.

# Development

## Overview

Game logic is contained in plain old ruby objects defined in `/models`.

An HTTP server exposing it is defined in `app.rb`. It has three endpoints:

`GET /`

`POST /actions`

`POST /messages`

There are two clients, one HTML-based, and one text-based. My plan at this point is for both to use this API, but the server will send back different representations (e.g. HTML to the web client, and a printable string to the textbased client) based on Accept headers or MIME types.

The server also uses websockets to send updates of game state. However, for the foreseeable, the websocket interface will be write-only from the server point of view and read-only from the client's.

## Setup

1. `gem install bundler`
2. `bundle install`
3. `ruby test/run.rb`
4. `ruby app.rb`
5. Visit `localhost:4567`

## TODO

- Development cards
- Endgame
- Text-based client

# License

Copyright (c) 2013 Andrew Ross

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
