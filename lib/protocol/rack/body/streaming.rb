# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2024, by Samuel Williams.

require "protocol/http/body/streamable"

module Protocol
	module Rack
		module Body
			class Streaming < ::Protocol::HTTP::Body::Streamable::ResponseBody
				def initialize(body, input = nil)
					@body = body
					
					super
				end
				
				def close(error = nil)
					if body = @body
						@body = nil
						if body.respond_to?(:close)
							body.close
						end
					end
					
					super
				end
			end
		end
	end
end
