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

require_relative 'body'
require_relative 'constants'
# require 'time'

require 'protocol/http/response'
require 'protocol/http/headers'

module Protocol
	module Rack
		# A wrapper for a `Rack` response.
		#
		# A Rack response consisting of `[status, headers, body]` includes various rack-specific elements, including:
		#
		# - A `headers['rack.hijack']` callback which bypasses normal response handling.
		# - Potentially invalid content length.
		# - Potentially invalid body when processing a `HEAD` request.
		# - Newline-separated header values.
		# - Other `rack.` specific header key/value pairs.
		#
		# This wrapper takes those issues into account and adapts the rack response tuple into a {Protocol::HTTP::Response}.
		class Response < ::Protocol::HTTP::Response
			# HTTP hop headers which *should* not be passed through the proxy.
			HOP_HEADERS = [
				'connection',
				'keep-alive',
				'public',
				'proxy-authenticate',
				'transfer-encoding',
				'upgrade',
			]
			
			# Process the rack response headers into into a {Protocol::HTTP::Headers} instance, along with any extra `rack.` metadata.
			# @returns [Tuple(Protocol::HTTP::Headers, Hash)]
			def self.wrap_headers(fields)
				headers = ::Protocol::HTTP::Headers.new
				meta = {}
				
				fields.each do |key, value|
					key = key.downcase
					
					if key.start_with?('rack.')
						meta[key] = value
					elsif value.is_a?(Array)
						value.each do |value|
							headers[key] = value
						end
					else
						headers[key] = value
					end
				end
				
				return headers, meta
			end
			
			# Wrap a rack response.
			# @parameter status [Integer] The rack response status.
			# @parameter headers [Duck(:each)] The rack response headers.
			# @parameter body [Duck(:each, :close) | Nil] The rack response body.
			# @parameter request [Protocol::HTTP::Request] The original request.
			def self.wrap(status, headers, body, request = nil)
				headers, meta = wrap_headers(headers)

				ignored = headers.extract(HOP_HEADERS)
				unless ignored.empty?
					Console.logger.warn(self, "Ignoring protocol-level headers: #{ignored.inspect}")
				end

				body = Body.wrap(status, headers, body, request&.body)

				if request&.head?
					# I thought about doing this in Output.wrap, but decided the semantics are too tricky. Specifically, the various ways a rack response body can be wrapped, and the need to invoke #close at the right point.
					body = ::Protocol::HTTP::Body::Head.for(body)
				end
				
				protocol = meta[RACK_PROTOCOL]
				
				# https://tools.ietf.org/html/rfc7231#section-7.4.2
				# headers.add('server', "falcon/#{Falcon::VERSION}")
				
				# https://tools.ietf.org/html/rfc7231#section-7.1.1.2
				# headers.add('date', Time.now.httpdate)
				
				return self.new(status, headers, body, protocol)
			end
			
			# Initialize the response wrapper.
			# @parameter status [Integer] The response status.
			# @parameter headers [Protocol::HTTP::Headers] The response headers.
			# @parameter body [Protocol::HTTP::Body] The response body.
			# @parameter protocol [String] The response protocol for upgraded requests.
			def initialize(status, headers, body, protocol = nil)
				super(nil, status, headers, body, protocol)
			end
		end
	end
end
