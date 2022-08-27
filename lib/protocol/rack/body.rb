# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022, by Samuel Williams.

require_relative 'body/streaming'
require_relative 'body/enumerable'
require 'protocol/http/body/completable'

module Protocol
	module Rack
		module Body
			CONTENT_LENGTH = 'content-length'
			
			def self.wrap(env, status, headers, body, input = nil)
				# In no circumstance do we want this header propagating out:
				if length = headers.delete(CONTENT_LENGTH)
					# We don't really trust the user to provide the right length to the transport.
					length = Integer(length)
				end
				
				# If we have an Async::HTTP body, we return it directly:
				if body.is_a?(::Protocol::HTTP::Body::Readable)
					# Ignore.
				elsif status == 200 and body.respond_to?(:to_path)
					begin
						# Don't mangle partial responses (206)
						body = ::Protocol::HTTP::Body::File.open(body.to_path).tap do
							body.close if body.respond_to?(:close) # Close the original body.
						end
					rescue Errno::ENOENT
						# If the file is not available, ignore.
					end
				elsif body.respond_to?(:each)
					body = Body::Enumerable.wrap(body, length)
				else
					body = Body::Streaming.new(body, input)
				end
				
				if response_finished = env[RACK_RESPONSE_FINISHED] and response_finished.any?
					body = ::Protocol::HTTP::Body::Completable.new(body, completion_callback(response_finished, env, status, headers))
				end
				
				return body
			end
			
			def self.completion_callback(response_finished, env, status, headers)
				proc do |error|
					response_finished.each do |callback|
						callback.call(env, status, headers, error)
					end
				end
			end
		end
	end
end
