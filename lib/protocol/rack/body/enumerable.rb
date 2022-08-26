# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022, by Samuel Williams.

require 'protocol/http/body/readable'
require 'protocol/http/body/file'

module Protocol
	module Rack
		module Body
			# Wraps the rack response body.
			#
			# The `rack` body must respond to `each` and must only yield `String` values. If the body responds to `close`, it will be called after iteration.
			class Enumerable < ::Protocol::HTTP::Body::Readable
				CONTENT_LENGTH = 'content-length'.freeze
				
				# Wraps an array into a buffered body.
				# @parameter body [Object] The `rack` response body.
				def self.wrap(body, length = nil)
					if body.is_a?(Array)
						length ||= body.sum(&:bytesize)
						return self.new(body, length)
					else
						return self.new(body, length)
					end
				end
				
				# Initialize the output wrapper.
				# @parameter body [Object] The rack response body.
				# @parameter length [Integer] The rack response length.
				def initialize(body, length)
					@length = length
					@body = body
					
					@chunks = nil
				end
				
				# The rack response body.
				attr :body
				
				# The content length of the rack response body.
				attr :length
				
				# Whether the body is empty.
				def empty?
					@length == 0 or (@body.respond_to?(:empty?) and @body.empty?)
				end
				
				# Whether the body can be read immediately.
				def ready?
					body.is_a?(Array) or body.respond_to?(:to_ary)
				end
				
				# Close the response body.
				def close(error = nil)
					if @body and @body.respond_to?(:close)
						@body.close
					end
					
					@body = nil
					@chunks = nil
					
					super
				end
				
				# Enumerate the response body.
				# @yields {|chunk| ...}
				# 	@parameter chunk [String]
				def each(&block)
					@body.each(&block)
				ensure
					self.close($!)
				end
				
				def stream?
					!@body.respond_to?(:each)
				end

				def call(stream)
					@body.call(stream)
				ensure
					self.close($!)
				end

				# Read the next chunk from the response body.
				# @returns [String | Nil]
				def read
					@chunks ||= @body.to_enum(:each)
					
					return @chunks.next
				rescue StopIteration
					return nil
				end
				
				def inspect
					"\#<#{self.class} length=#{@length.inspect} body=#{@body.class}>"
				end
			end
		end
	end
end
