# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022, by Samuel Williams.

require 'protocol/http/body/readable'
require 'protocol/http/body/stream'

module Protocol
	module Rack
		module Body
			# Wraps a streaming response body into a compatible Protocol::HTTP body.
			class Streaming < ::Protocol::HTTP::Body::Readable
				def initialize(block, input = nil)
					@block = block
					@input = input
					@output = nil
				end
				
				attr :block
				
				class Output
					def initialize(input, block)
						stream = ::Protocol::HTTP::Body::Stream.new(input, self)
						@fiber = Fiber.new do
							block.call(stream)
							@fiber = nil
						end
					end
					
					def write(chunk)
						Fiber.yield(chunk)
					end
					
					def close
						@fiber = nil
					end
					
					def read
						@fiber&.resume
					end
				end
				
				# Invokes the block in a fiber which yields chunks when they are available.
				def read
					@output ||= Output.new(@input, @block)
					return @output.read
				end
				
				def stream?
					true
				end
				
				def call(stream)
					raise "Streaming body has already been read!" if @output
					@block.call(stream)
				end
			end
		end
	end
end
