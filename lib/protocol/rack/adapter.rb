# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2023, by Samuel Williams.

require 'rack'

require_relative 'adapter/rack2'
require_relative 'adapter/rack3'

module Protocol
	module Rack
		module Adapter
			if ::Rack.release >= "3"
				IMPLEMENTATION = Rack3
			else
				IMPLEMENTATION = Rack2
			end
			
			def self.new(app)
				IMPLEMENTATION.wrap(app)
			end
			
			def self.make_response(env, response)
				IMPLEMENTATION.make_response(env, response)
			end
			
			def self.parse_file(...)
				IMPLEMENTATION.parse_file(...)
			end
		end
	end
end
