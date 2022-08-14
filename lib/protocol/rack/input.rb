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

require 'async/io/buffer'
require 'protocol/http/body/rewindable'

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
				
				# Will hold remaining data in `#read`.
				@buffer = nil
				@finished = @body.nil?
			end
			
			# The input body.
			# @attribute [Protocol::HTTP::Body::Readable]
			attr :body
			
			# Enumerate chunks of the request body.
			# @yields {|chunk| ...}
			# 	@parameter chunk [String]
			def each(&block)
				return to_enum unless block_given?
				
				while chunk = gets
					yield chunk
				end
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
			
			# Behaves like IO#read. Its signature is read([length, [buffer]]). If given, length must be a non-negative Integer (>= 0) or nil, and buffer must be a String and may not be nil. If length is given and not nil, then this method reads at most length bytes from the input stream. If length is not given or nil, then this method reads all data until EOF. When EOF is reached, this method returns nil if length is given and not nil, or “” if length is not given or is nil. If buffer is given, then the read data will be placed into buffer instead of a newly created String object.
			# @parameter length [Integer] the amount of data to read
			# @parameter buffer [String] the buffer which will receive the data
			# @returns [String] a buffer containing the data
			def read(length = nil, buffer = nil)
				return '' if length == 0
				
				buffer ||= Async::IO::Buffer.new

				# Take any previously buffered data and replace it into the given buffer.
				if @buffer
					buffer.replace(@buffer)
					@buffer = nil
				end
				
				if length
					while buffer.bytesize < length and chunk = read_next
						buffer << chunk
					end
					
					# This ensures the subsequent `slice!` works correctly.
					buffer.force_encoding(Encoding::BINARY)

					# This will be at least one copy:
					@buffer = buffer.byteslice(length, buffer.bytesize)
					
					# This should be zero-copy:
					buffer.slice!(length)
					
					if buffer.empty?
						return nil
					else
						return buffer
					end
				else
					while chunk = read_next
						buffer << chunk
					end
					
					return buffer
				end
			end
			
			# Read at most `length` bytes from the stream. Will avoid reading from the underlying stream if possible.
			def read_partial(length = nil)
				if @buffer
					buffer = @buffer
					@buffer = nil
				else
					buffer = read_next
				end
				
				if buffer and length
					if buffer.bytesize > length
						# This ensures the subsequent `slice!` works correctly.
						buffer.force_encoding(Encoding::BINARY)

						@buffer = buffer.byteslice(length, buffer.bytesize)
						buffer.slice!(length)
					end
				end
				
				return buffer
			end
			
			def read_nonblock(length, buffer = nil)
				@buffer ||= read_next
				chunk = nil
				
				unless @buffer
					buffer&.clear
					return
				end
				
				if @buffer.bytesize > length
					chunk = @buffer.byteslice(0, length)
					@buffer = @buffer.byteslice(length, @buffer.bytesize)
				else
					chunk = @buffer
					@buffer = nil
				end
				
				if buffer
					buffer.replace(chunk)
				else
					buffer = chunk
				end
				
				return buffer
			end
			
			# Read the next chunk of data from the input stream.
			#
			# `gets` must be called without arguments and return a `String`, or `nil` when the input stream has no more data.
			#
			# @returns [String | Nil] The next chunk from the body.
			def gets
				if @buffer.nil?
					return read_next
				else
					buffer = @buffer
					@buffer = nil
					return buffer
				end
			end
			
			# Close the input and output bodies.
			def close(error = nil)
				self.close_read
				self.close_write

				return nil
			ensure
				@closed = true
			end
			
			# Whether the stream has been closed.
			def closed?
				@closed
			end
			
			# Whether there are any output chunks remaining?
			def empty?
				@output.empty?
			end
			
			private
			
			def read_next
				if @input
					@input.read
				else
					@input = nil
					raise IOError, "Stream is not readable, input has been closed!"
				end
			end
		end
	end
end
