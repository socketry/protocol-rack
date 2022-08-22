# frozen_string_literal: true

# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'protocol/http/request'
require 'protocol/http/headers'

require_relative 'body/input_wrapper'

module Protocol
	module Rack
		class Request < ::Protocol::HTTP::Request
			def self.[](env)
				env['protocol.http.request'] ||= new(env)
			end

			def initialize(env)
				@env = env

				super(
					@env['rack.url_scheme'],
					@env['HTTP_HOST'],
					@env['REQUEST_METHOD'],
					@env['PATH_INFO'],
					@env['SERVER_PROTOCOL'],
					self.class.headers(@env),
					Body::InputWrapper.new(@env['rack.input']),
					self.class.protocol(@env)
				)
			end

			HTTP_UPGRADE = 'HTTP_UPGRADE'

			def self.protocol(env)
				if protocols = env['rack.protocol']
					return Array(protocols)
				elsif protocols = env[HTTP_UPGRADE]
					return protocols.split(/\s*,\s*/)
				end
			end

			def self.headers(env)
				headers = ::Protocol::HTTP::Headers.new
				env.each do |key, value|			
					if key.start_with?('HTTP_')
						next if key == 'HTTP_HOST'
						headers[key[5..-1].gsub('_', '-').downcase] = value
					end
				end

				return headers
			end
		end
	end
end
