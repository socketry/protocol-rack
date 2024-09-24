#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2024, by Samuel Williams.

require "async"
require "async/http/server"
require "async/http/client"
require "async/http/endpoint"
require_relative "../../lib/protocol/rack/adapter"

app = proc{|env| [200, {}, ["Hello World"]]}
middleware = Protocol::Rack::Adapter.new(app)

Async do
	endpoint = Async::HTTP::Endpoint.parse("http://localhost:9292")
		
	server_task = Async(transient: true) do
		server = Async::HTTP::Server.new(middleware, endpoint)
		server.run
	end
		
	client = Async::HTTP::Client.new(endpoint)
	pp client.get("/").read
end
