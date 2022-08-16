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

require 'rack'

require_relative 'input'
require_relative 'response'

require 'console'

module Protocol
	module Rack
		# CGI keys <https://tools.ietf.org/html/rfc3875#section-4.1>:
		module CGI
			HTTP_HOST = 'HTTP_HOST'
			PATH_INFO = 'PATH_INFO'
			REQUEST_METHOD = 'REQUEST_METHOD'
			REQUEST_PATH = 'REQUEST_PATH'
			REQUEST_URI = 'REQUEST_URI'
			SCRIPT_NAME = 'SCRIPT_NAME'
			QUERY_STRING = 'QUERY_STRING'
			SERVER_PROTOCOL = 'SERVER_PROTOCOL'
			SERVER_NAME = 'SERVER_NAME'
			SERVER_PORT = 'SERVER_PORT'
			REMOTE_ADDR = 'REMOTE_ADDR'
			CONTENT_TYPE = 'CONTENT_TYPE'
			CONTENT_LENGTH = 'CONTENT_LENGTH'
			
			# Header constants:
			HTTP_X_FORWARDED_PROTO = 'HTTP_X_FORWARDED_PROTO'
		end
		
		# Rack environment variables:
		RACK_ERRORS = 'rack.errors'
		RACK_LOGGER = 'rack.logger'
		RACK_INPUT = 'rack.input'
		RACK_URL_SCHEME = 'rack.url_scheme'
		RACK_PROTOCOL = 'rack.protocol'
	end
end
