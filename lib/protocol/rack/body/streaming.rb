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
				end
				
				attr :block

				def each(&block)
					stream = ::Protocol::HTTP::Body::Stream.new(@input, Output.new(block))
					
					@block.call(stream)
				end

				def stream?
					true
				end

				def call(stream)
					@block.call(stream)
				end
				
				class Output
					def initialize(block)
						@block = block
					end
					
					def write(chunk)
						@block.call(chunk)
					end
					
					def close
						@block = nil
					end
					
					def empty?
						true
					end
				end
			end
		end
	end
end
