# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2024, by Samuel Williams.
# Copyright, 2023, by Genki Takiuchi.

require "protocol/http/body/stream"

module Protocol
	module Rack
		# Wraps a streaming input body into the interface required by `rack.input`.
		#
		# The input stream is an `IO`-like object which contains the raw HTTP POST data. When applicable, its external encoding must be `ASCII-8BIT` and it must be opened in binary mode, for Ruby 1.9 compatibility. The input stream must respond to `gets`, `each`, `read` and `rewind`.
		#
		# This implementation is not always rewindable, to avoid buffering the input when handling large uploads. See {Rewindable} for more details.
		class Input
			# Initialize the input wrapper.
			# @parameter body [Protocol::HTTP::Body::Readable]
			def initialize(body)
				@body = body
				@closed = false
				
				# Will hold remaining data in `#read`.
				@buffer = nil
			end
			
			# The input body.
			# @attribute [Protocol::HTTP::Body::Readable]
			attr :body
			
			include Protocol::HTTP::Body::Stream::Reader
			
			# Enumerate chunks of the request body.
			# @yields {|chunk| ...}
			# 	@parameter chunk [String]
			def each(&block)
				return to_enum unless block_given?
				
				return if closed? 
				
				while chunk = read_partial
					yield chunk
				end
			end
			
			# Close the input and output bodies.
			def close(error = nil)
				@closed = true
				
				if @body
					@body.close(error)
					@body = nil
				end
				
				return nil
			end
			
			# Rewind the input stream back to the start.
			#
			# `rewind` must be called without arguments. It rewinds the input stream back to the beginning. It must not raise Errno::ESPIPE: that is, it may not be a pipe or a socket. Therefore, handler developers must buffer the input data into some rewindable object if the underlying input stream is not rewindable.
			#
			# @returns [Boolean] Whether the body could be rewound.
			def rewind
				if @body and @body.respond_to?(:rewind)
					# If the body is not rewindable, this will fail.
					@body.rewind
					@buffer = nil
					@finished = false
					
					return true
				end
				
				return false
			end
			
			# Whether the stream has been closed.
			def closed?
				@closed or @body.nil?
			end
			
			# Whether there are any input chunks remaining?
			def empty?
				@body.nil?
			end
			
			private
			
			def read_next
				if @body
					# User's may forget to call #close...
					if chunk = @body.read
						# If the user reads exactly the content length, we close the stream automatically:
						# https://github.com/socketry/async-http/issues/183
						if @body.empty?
							@body.close
							@body = nil
						end
						
						return chunk
					else
						# So if we are at the end of the stream, we close it automatically:
						@body.close
						@body = nil
					end
				elsif @closed
					raise IOError, "Stream is not readable, input has been closed!"
				end
			end
		end
	end
end
