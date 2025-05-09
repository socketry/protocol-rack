#!/usr/bin/env ruby
# frozen_string_literal: true

require "sus"
require "rack/lint"
require "sus/fixtures/console"
require "protocol/rack/server_context"

module Protocol
	module Rack
		AnAdapter = Sus::Shared("an adapter") do
			AServer = Sus::Shared("a server") do
				include Protocol::Rack::ServerContext
	
				let(:protocol) {subject}
				
				with "successful response" do
					let(:app) do
						::Rack::Lint.new(
							lambda do |env|
								[200, {}, ["Hello World!"]]
							end
						)
					end
					
					let(:response) {client.get("/")}
					
					it "get valid HTTP_HOST" do
						expect(response.read).to be == "Hello World!"
					end
				end
				
				with "HTTP_HOST" do
					let(:app) do
						lambda do |env|
							[200, {}, ["HTTP_HOST: #{env['HTTP_HOST']}"]]
						end
					end
					
					let(:response) {client.get("/")}
					
					it "get valid HTTP_HOST" do
						expect(response.read).to be =~ /HTTP_HOST: (.*?):(\d+)+/
					end
				end
				
				with "connection: close", timeout: 1 do
					let(:app) do
						lambda do |env|
							[200, {"connection" => "close"}, ["Hello World!"]]
						end
					end
					
					let(:response) {client.get("/")}
					
					it "get valid response" do
						expect(response.read).to be == "Hello World!"
					end
				end
				
				with "non-string header value" do
					let(:app) do
						lambda do |env|
							[200, {"x-custom" => 123}, ["Hello World!"]]
						end
					end
					
					let(:response) {client.get("/")}
					
					it "get valid response" do
						expect(response.read).to be == "Hello World!"
						expect(response.headers["x-custom"]).to be == ["123"]
					end
				end
				
				with "REQUEST_URI", timeout: 1 do
					let(:app) do
						lambda do |env|
							[200, {}, ["REQUEST_URI: #{env['REQUEST_URI']}"]]
						end
					end
					
					let(:response) {client.get("/?foo=bar")}
					
					it "get valid REQUEST_URI" do
						expect(response.read).to be == "REQUEST_URI: /?foo=bar"
					end
				end
				
				with "streaming response" do
					let(:app) do
						lambda do |env|
							body = lambda do |stream|
								stream.write("Hello Streaming World")
								stream.close
							end
							
							[200, {}, body]
						end
					end
					
					let(:response) {client.get("/")}
					
					it "can read streaming response" do
						expect(response.read).to be == "Hello Streaming World"
					end
				end
			end
			
			[
				Async::HTTP::Protocol::HTTP10,
				Async::HTTP::Protocol::HTTP11,
				Async::HTTP::Protocol::HTTP2,
			].each do |klass|
				describe(klass, unique: klass.name) do
					it_behaves_like AServer
				end
			end
			
			with "error handling" do
				with "nil response" do
					let(:app) {->(env) {nil}}
					
					it "raises an error" do
						expect(response.status).to be == 500
						expect(response.read).to be == "ArgumentError: Status must be an integer!"
					end
				end
				
				with "nil headers" do
					let(:app) {->(env) {[200, nil, []]}}
					
					it "raises an error" do
						expect(response.status).to be == 500
						expect(response.read).to be == "ArgumentError: Headers must not be nil!"
					end
				end
			end
		end
	end
end
