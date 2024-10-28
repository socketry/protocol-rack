# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2024, by Samuel Williams.

require "rack"

module Protocol
	module Rack
		module Adapter
			VERSION = ENV.fetch("PROTOCOL_RACK_ADAPTER_VERSION", ::Rack.release)
			
			if VERSION >= "3.1"
				require_relative "adapter/rack31"
				IMPLEMENTATION = Rack31
			elsif VERSION >= "3"
				require_relative "adapter/rack3"
				IMPLEMENTATION = Rack3
			else
				require_relative "adapter/rack2"
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
