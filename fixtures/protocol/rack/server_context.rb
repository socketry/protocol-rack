# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2024, by Samuel Williams.

require "sus/fixtures/async/http/server_context"

module Protocol
	module Rack
		module ServerContext
			include Sus::Fixtures::Async::HTTP::ServerContext
			
			def app
				->(env){[200, {}, ["Hello World!"]]}
			end
			
			def middleware
				Protocol::Rack::Adapter.new(app)
			end
		end
	end
end
