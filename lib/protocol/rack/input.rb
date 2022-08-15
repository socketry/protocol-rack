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
require 'protocol/http/body/stream'

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
			
			include Protocol::HTTP::Body::Stream::Reader
			
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
				if @body
					@body.close(error)
					@body = nil
				end
				
				return nil
			end
			
			# Whether the stream has been closed.
			def closed?
				@body.nil?
			end
			
			# Whether there are any output chunks remaining?
			def empty?
				@output.empty?
			end
			
			private
			
			def read_next
				if @body
					@body.read
				else
					@body = nil
					raise IOError, "Stream is not readable, input has been closed!"
				end
			end
		end
	end
end
