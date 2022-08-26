# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022, by Samuel Williams.

require_relative 'body/streaming'
require_relative 'body/enumerable'

module Protocol
	module Rack
		module Body
			CONTENT_LENGTH = 'content-length'
			
			def self.wrap(status, headers, body, input = nil)
				# In no circumstance do we want this header propagating out:
				if length = headers.delete(CONTENT_LENGTH)
					# We don't really trust the user to provide the right length to the transport.
					length = Integer(length)
				end

				# If we have an Async::HTTP body, we return it directly:
				if body.is_a?(::Protocol::HTTP::Body::Readable)
					return body
				elsif status == 200 and body.respond_to?(:to_path)
					begin
						# Don't mangle partial responses (206)
						return ::Protocol::HTTP::Body::File.open(body.to_path).tap do
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
			end
		end
	end
end
