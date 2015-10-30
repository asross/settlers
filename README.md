# Settlers

of Catan!

## Summary

Play Settlers of Catan on your home computer with your friends by running the server on one machine and having others connect to it either through a web or text interface.

## Setup

1. `bundle`
2. `ruby app.rb`
3. Visit `localhost:4567`
4. Or run `ruby text/text_client.rb`

To run tests, `ruby test.rb`

## Demo

[Play a demo here.](http://54.200.205.31:4567:4567)

If you clone this repository, you can also connect to this server using the text interface by running:

```
APP_URL=http://54.200.205.31:4567 WS_URL=http://54.200.205.31:8080 ruby text/client.rb
```

![settlers](https://cloud.githubusercontent.com/assets/1022564/10851499/d192053e-7f01-11e5-839d-b19237b8b6c5.gif)

## License

Copyright (c) 2015 Andrew Ross

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
