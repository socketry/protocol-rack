# Protocol::Rack

Provides abstractions for working with the Rack specification on top of [`Protocol::HTTP`](https://github.com/socketry/protocol-http). This would, in theory, allow you to run any `Protocol::HTTP` compatible application on top any rack-compatible server.

[![Development Status](https://github.com/socketry/protocol-rack/workflows/Test/badge.svg)](https://github.com/socketry/protocol-rack/actions?workflow=Test)

## Features

  - Supports Rack v2 and Rack v3 application adapters.
  - Supports Rack environment to `Protocol::HTTP::Request` adapter.
 
## Usage

### Application Adapter

Given a rack application, you can adapt it for use on `async-http`:

```ruby
require 'async'
require 'async/http/server'
require 'async/http/client'
require 'async/http/endpoint'
require 'protocol/rack/adapter'

app = proc{|env| [200, {}, ["Hello World"]]}
middleware = Protocol::Rack::Adapter.new(app)

Async do
  endpoint = Async::HTTP::Endpoint.parse("http://localhost:9292")
  
  server_task = Async(transient: true) do
    server = Async::HTTP::Server.new(middleware, endpoint)
    server.run
  end
  
  client = Async::HTTP::Client.new(endpoint)
  puts client.get("/").read
  # "Hello World"
end
```

### Server Adapter

While not tested, in theory any Rack compatible server can host `Protocol::HTTP` compatible middlewares.

```ruby
require 'protocol/http/middleware'
require 'protocol/rack'

# Your native application:
middleware = Protocol::HTTP::Middleware::HelloWorld

run proc{|env|
  # Convert the rack request to a compatible rich request object:
  request = Protocol::Rack::Request[env]
  
  # Call your application
  response = middleware.call(request)
  
  Protocol::Rack::Adapter.make_response(env, response)
}
```

## Contributing

We welcome contributions to this project.

1.  Fork it.
2.  Create your feature branch (`git checkout -b my-new-feature`).
3.  Commit your changes (`git commit -am 'Add some feature'`).
4.  Push to the branch (`git push origin my-new-feature`).
5.  Create new Pull Request.

## See Also

  - [protocol-http](https://github.com/socketry/protocol-http) — General abstractions for HTTP client/server implementations.
  - [async-http](https://github.com/socketry/async-http) — Asynchronous HTTP client and server, supporting multiple HTTP protocols & TLS, which can host the Rack application adapters (and is used by this gem for testing).

## License

Released under the MIT license.

Copyright, 2022, by [Samuel G. D. Williams](http://www.codeotaku.com/samuel-williams).

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
