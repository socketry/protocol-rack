# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022, by Samuel Williams.

require 'protocol/http/body/readable'
require 'protocol/http/body/stream'

module Protocol
	module Rack
		module Body
			# Used for wrapping a generic `rack.input` object into a readable body.
			class InputWrapper < Protocol::HTTP::Body::Readable
				BLOCK_SIZE = 1024*4
				
				def initialize(io, block_size: BLOCK_SIZE)
					@io = io
					@block_size = block_size
					
					super()
				end
				
				def close(error = nil)
					if @io
						@io.close
						@io = nil
					end
				end
				
				# def join
				# 	@io.read.tap do |buffer|
				# 		buffer.force_encoding(Encoding::BINARY)
				# 	end
				# end
				
				def read
					@io&.read(@block_size)
				end
			end
		end
	end
end
