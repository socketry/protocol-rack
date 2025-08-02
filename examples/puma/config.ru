# frozen_string_literal: true

require "protocol/http/middleware"
require_relative "../../lib/protocol/rack"

# Your native application:
middleware = Protocol::HTTP::Middleware::HelloWorld

run proc{|env|
	# Convert the rack request to a compatible rich request object:
	request = Protocol::Rack::Request[env]
	
	# Call your application
	response = middleware.call(request)
	
	Protocol::Rack::Adapter.make_response(env, response)
}
