# frozen_string_literal: true

# Copyright, 2017, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'console'

require_relative 'generic'

module Protocol
	module Rack
		module Adapter
			class Rack3 < Generic
				def self.wrap(app)
					self.new(app)
				end
				
				def make_environment(request)
					request_path, query_string = request.path.split('?', 2)
					server_name, server_port = (request.authority || '').split(':', 2)
					
					env = {
						PROTOCOL_HTTP_REQUEST => request,
						
						RACK_INPUT => Input.new(request.body),
						RACK_ERRORS => $stderr,
						RACK_LOGGER => self.logger,

						# The request protocol, either from the upgrade header or the HTTP/2 pseudo header of the same name.
						RACK_PROTOCOL => request.protocol,
						
						# The HTTP request method, such as “GET” or “POST”. This cannot ever be an empty string, and so is always required.
						CGI::REQUEST_METHOD => request.method,
						
						# The initial portion of the request URL's “path” that corresponds to the application object, so that the application knows its virtual “location”. This may be an empty string, if the application corresponds to the “root” of the server.
						CGI::SCRIPT_NAME => '',
						
						# The remainder of the request URL's “path”, designating the virtual “location” of the request's target within the application. This may be an empty string, if the request URL targets the application root and does not have a trailing slash. This value may be percent-encoded when originating from a URL.
						CGI::PATH_INFO => request_path,
						CGI::REQUEST_PATH => request_path,
						CGI::REQUEST_URI => request.path,

						# The portion of the request URL that follows the ?, if any. May be empty, but is always required!
						CGI::QUERY_STRING => query_string || '',
						
						# The server protocol (e.g. HTTP/1.1):
						CGI::SERVER_PROTOCOL => request.version,
						
						# The request scheme:
						RACK_URL_SCHEME => request.scheme,
						
						# I'm not sure what sane defaults should be here:
						CGI::SERVER_NAME => server_name,
						CGI::SERVER_PORT => server_port,
					}
					
					self.unwrap_request(request, env)
					
					return env
				end
				
				def self.make_response(env, response)
					# These interfaces should be largely compatible:
					headers = response.headers.to_h
					if protocol = response.protocol
						headers['rack.protocol'] = protocol
					end
					
					if body = response.body and body.stream?
						# Force streaming response:
						body = body.method(:call)
					end
					  
					[response.status, headers, body]
				end
			end
		end
	end
end
