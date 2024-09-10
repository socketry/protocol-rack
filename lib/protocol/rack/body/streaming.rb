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
						
						@from = nil
						
						@fiber = Fiber.new do |from|
							@from = from
							block.call(stream)
							@fiber = nil
						end
					end
					
					def write(chunk)
						if from = @from
							@from = nil
							@from = from.transfer(chunk)
						else
							raise RuntimeError, "Stream is not being read!"
						end
					end
					
					def close(error = nil)
						@fiber = nil
						
						if from = @from
							@from = nil
							if error
								from.raise(error)
							else
								from.transfer(nil)
							end
						end
					end
					
					def close_write(error = nil)
						close(error)
					end
					
					def read
						raise RuntimeError, "Stream is already being read!" if @from
						
						@fiber&.transfer(Fiber.current)
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
