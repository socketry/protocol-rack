# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022, by Samuel Williams.

require 'console'

require_relative '../constants'
require_relative '../input'
require_relative '../response'

module Protocol
	module Rack
		module Adapter
			class Generic
				def self.wrap(app)
					self.new(app)
				end
				
				# Initialize the rack adaptor middleware.
				# @parameter app [Object] The rack middleware.
				def initialize(app)
					@app = app
					
					raise ArgumentError, "App must be callable!" unless @app.respond_to?(:call)
				end
				
				def logger
					Console.logger
				end

				# Unwrap raw HTTP headers into the CGI-style expected by Rack middleware.
				#
				# Rack separates multiple headers with the same key, into a single field with multiple lines.
				#
				# @parameter headers [Protocol::HTTP::Headers] The raw HTTP request headers.
				# @parameter env [Hash] The rack request `env`.
				def unwrap_headers(headers, env)
					headers.each do |key, value|
						http_key = "HTTP_#{key.upcase.tr('-', '_')}"
						
						if current_value = env[http_key]
							env[http_key] = "#{current_value};#{value}"
						else
							env[http_key] = value
						end
					end
				end
				
				# Process the incoming request into a valid rack `env`.
				#
				# - Set the `env['CONTENT_TYPE']` and `env['CONTENT_LENGTH']` based on the incoming request body. 
				# - Set the `env['HTTP_HOST']` header to the request authority.
				# - Set the `env['HTTP_X_FORWARDED_PROTO']` header to the request scheme.
				# - Set `env['REMOTE_ADDR']` to the request remote adress.
				#
				# @parameter request [Protocol::HTTP::Request] The incoming request.
				# @parameter env [Hash] The rack `env`.
				def unwrap_request(request, env)
					if content_type = request.headers.delete('content-type')
						env[CGI::CONTENT_TYPE] = content_type
					end
					
					# In some situations we don't know the content length, e.g. when using chunked encoding, or when decompressing the body.
					if body = request.body and length = body.length
						env[CGI::CONTENT_LENGTH] = length.to_s
					end
					
					self.unwrap_headers(request.headers, env)
					
					# HTTP/2 prefers `:authority` over `host`, so we do this for backwards compatibility.
					env[CGI::HTTP_HOST] ||= request.authority
								
					if request.respond_to?(:remote_address)
						if remote_address = request.remote_address
							env[CGI::REMOTE_ADDR] = remote_address.ip_address if remote_address.ip?
						end
					end
				end
				
				# Build a rack `env` from the incoming request and apply it to the rack middleware.
				#
				# @parameter request [Protocol::HTTP::Request] The incoming request.
				def call(request)
					env = self.make_environment(request)
					
					status, headers, body = @app.call(env)
					
					headers, meta = self.wrap_headers(headers)
					
					return Response.wrap(env, status, headers, meta, body, request)
				rescue => exception
					Console.logger.error(self) {exception}
					
					body&.close if body.respond_to?(:close)
					
					env&.[](RACK_RESPONSE_FINISHED)&.each do |callback|
						callback.call(env, status, headers, exception)
					end
					
					return failure_response(exception)
				end
				
				# Generate a suitable response for the given exception.
				# @parameter exception [Exception]
				# @returns [Protocol::HTTP::Response]
				def failure_response(exception)
					Protocol::HTTP::Response.for_exception(exception)
				end
			end
		end
	end
end
