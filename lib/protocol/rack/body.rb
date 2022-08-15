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

module Protocol
	module Rack
		module Body
			CONTENT_LENGTH = 'content-length'
			
			def self.wrap(status, headers, body)
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
					body = Body::Streaming.new(body)
				end
			end
		end
	end
end
