# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2025, by Samuel Williams.

require "sus/fixtures/console"

require "protocol/rack/adapter"
require "protocol/rack/server_context"

require "rack/lint"

describe Protocol::Rack::Adapter do
	include Sus::Fixtures::Console::CapturedLogger
	
	let(:rackup_path) {File.expand_path(".adapter/config.ru", __dir__)}
	
	it "can load rackup files" do
		expect(subject.parse_file(rackup_path)).to be_a(Proc)
	end
	
	with ".make_response" do
		let(:env) {Rack::MockRequest.env_for("/")}
		
		it "can make a response" do
			response = Protocol::HTTP::Response[200, headers: {}, body: ["Hello World!"]]
			status, headers, body = subject.make_response(env, response)
			
			expect(status).to be == 200
			expect(headers).to be == {}
			expect(body.join).to be == "Hello World!"
		end
		
		it "can make a streaming response" do
			stream_proc = lambda do |stream|
				stream.write("Hello Streaming World")
				stream.close
			end
			
			body = Protocol::Rack::Body::Streaming.new(stream_proc)
			
			response = Protocol::HTTP::Response[200, headers: {}, body: body]
			status, headers, body = subject.make_response(env, response)
			
			expect(status).to be == 200
			if headers.include?(Protocol::Rack::RACK_HIJACK)
				hijack_proc = headers[Protocol::Rack::RACK_HIJACK]
				expect(hijack_proc).to be(:respond_to?, :call)
			else
				expect(body).to be(:respond_to?, :call)
			end
		end
		
		it "can wrap headers" do
			response = Protocol::HTTP::Response[200, headers: {"x-custom" => "123"}, body: ["Hello World!"]]
			status, headers, body = subject.make_response(env, response)
			
			x_custom = headers["x-custom"]
			
			expect(x_custom).to (be == "123").or(be == ["123"])
		end
		
		it "can wrap multi-value headers" do
			response = Protocol::HTTP::Response[200, headers: [["x-custom", "a=b"], ["x-custom", "x=y"]], body: ["Hello World!"]]
			
			status, headers, body = subject.make_response(env, response)
			
			x_custom = headers["x-custom"]
			
			if subject::VERSION < "3"
				expect(x_custom).to be == "a=b\nx=y"
			else
				expect(x_custom).to be == ["a=b", "x=y"]
			end
		end
	end
	
	AnApplication = Sus::Shared("an application") do
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
				skip "Streaming response not supported" if Protocol::Rack::Adapter::VERSION < "2"
				
				expect(response.read).to be == "Hello Streaming World"
			end
		end
		
		with "error handling" do
			let(:response) {client.get("/")}
			
			with "nil response" do
				let(:app) {->(env){nil}}
				
				it "raises an error" do
					expect(response.status).to be == 500
					expect(response.read).to be == "ArgumentError: Status must be an integer!"
				end
			end
			
			with "nil headers" do
				let(:app) {->(env){[200, nil, []]}}
				
				it "raises an error" do
					expect(response.status).to be == 500
					expect(response.read).to be == "ArgumentError: Headers must not be nil!"
				end
			end
		end
	end
	
	[
		Async::HTTP::Protocol::HTTP10,
		Async::HTTP::Protocol::HTTP11,
		Async::HTTP::Protocol::HTTP2,
	].each do |klass|
		describe(klass, unique: klass.name) do
			# The adapter is Rack version specific, so we run integration tests in CI with different versions of Rack to ensure compatibility.
			it_behaves_like AnApplication
		end
	end
end
