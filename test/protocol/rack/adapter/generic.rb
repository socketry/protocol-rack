# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2025, by Samuel Williams.
# Copyright, 2025, by Francisco Mejia.

require "sus/fixtures/console"
require "protocol/rack/adapter/generic"
require "protocol/http/request"

describe Protocol::Rack::Adapter::Generic do
	include Sus::Fixtures::Console::CapturedLogger
	
	let(:app) {->(env){[200, {}, []]}}
	let(:adapter) {subject.new(app)}
	
	it "can instantiate an adapter" do
		expect(adapter).not.to be_nil
	end
	
	with "#unwrap_headers" do
		with "cookie header" do
			let(:fields) {[["cookie", "a=b"], ["cookie", "x=y"]]}
			let(:env) {Hash.new}
			
			it "should merge duplicate headers" do
				adapter.unwrap_headers(fields, env)
				
				# I'm not convinced this is standard behaviour:
				expect(env).to be == {"HTTP_COOKIE" => "a=b;x=y"}
			end
		end
		
		with "multiple accept headers" do
			let(:fields) {[["accept", "text/html"], ["accept", "application/json"]]}
			let(:env) {Hash.new}
			
			it "should merge duplicate headers" do
				adapter.unwrap_headers(fields, env)
				
				expect(env).to be == {"HTTP_ACCEPT" => "text/html,application/json"}
			end
		end
	end
	
	with "an exception" do
		let(:exception) {StandardError.new("Something went wrong")}
		let(:response) {adapter.failure_response(exception)}
		
		it "can generate a failure response" do
			expect(response.status).to be == 500
		end
	end
	
	with "a request with a content-type header" do
		let(:env) {Hash.new}
		let(:request) {Protocol::HTTP::Request["GET", "/", {"content-type" => "text/plain"}, nil]}
		
		it "can unwrap requests with the CONTENT_TYPE key" do
			adapter.unwrap_request(request, env)
			
			expect(env).to have_keys("CONTENT_TYPE" => be == "text/plain")
		end
	end
	
	with "app server without SERVER_PORT" do
		let(:request) do
			Protocol::HTTP::Request.new("https", "example.com", "GET", "/", "http/1.1", Protocol::HTTP::Headers[{"accept" => "text/html"}], nil)
		end
		
		it "does not include SERVER_PORT in the Rack environment" do
			env = adapter.make_environment(request)
			
			expect(env).not.to have_keys(Protocol::Rack::CGI::SERVER_PORT)
		end
	end
	
	with "a app that returns nil" do
		let(:app) {->(env){nil}}
		let(:request) {Protocol::HTTP::Request["GET", "/", {"content-type" => "text/plain"}, nil]}
		
		it "can generate a failure response" do
			response = adapter.call(request)
			expect(response.status).to be == 500
			expect(response.read).to be == "ArgumentError: Status must be an integer!"
		end
	end
	
	with "nil headers" do
		let(:app) {->(env){[200, nil, []]}}
		let(:request) {Protocol::HTTP::Request["GET", "/", {}, nil]}
		
		it "returns a failure response for nil headers" do
			response = adapter.call(request)
			expect(response.status).to be == 500
			expect(response.read).to be == "ArgumentError: Headers must not be nil!"
		end
	end
	
	with "protocol upgrade" do
		let(:app) {->(env){[200, {}, []]}}
		let(:request) {Protocol::HTTP::Request["GET", "/", {"upgrade" => "websocket"}, nil]}
		
		it "handles protocol upgrade with rack.protocol" do
			env = {"rack.protocol" => "websocket"}
			headers = {}
			response = Protocol::HTTP::Response[200, {}, []]
			response.protocol = "websocket"
			
			adapter.class.extract_protocol(env, response, headers)
			expect(headers["rack.protocol"]).to be == "websocket"
		end
		
		it "handles protocol upgrade with HTTP_UPGRADE" do
			env = {Protocol::Rack::CGI::HTTP_UPGRADE => "websocket"}
			headers = {}
			response = Protocol::HTTP::Response[200, {}, []]
			response.protocol = "websocket"
			
			adapter.class.extract_protocol(env, response, headers)
			expect(headers["upgrade"]).to be == "websocket"
			expect(headers["connection"]).to be == "upgrade"
		end
	end
	
	with "response callbacks" do
		let(:callback_called) {false}
		let(:callback) {->(env, status, headers, exception){@callback_called = true}}
		let(:app) do
			proc do |env|
				env[Protocol::Rack::RACK_RESPONSE_FINISHED] = [callback]
				raise StandardError.new("Test error")
			end
		end
		let(:request) {Protocol::HTTP::Request["GET", "/", {}, nil]}
		
		it "calls response callbacks on failure" do
			@callback_called = false
			
			response = adapter.call(request)
			
			expect(@callback_called).to be == true
			
			expect(response.status).to be == 500
			expect(response.read).to be == "StandardError: Test error"
		end
		
		it "invokes callbacks in reverse order of registration on error" do
			call_order = []
			
			callback1 = proc do |env, status, headers, error|
				call_order << 1
			end
			
			callback2 = proc do |env, status, headers, error|
				call_order << 2
			end
			
			callback3 = proc do |env, status, headers, error|
				call_order << 3
			end
			
			app_with_callbacks = proc do |env|
				env[Protocol::Rack::RACK_RESPONSE_FINISHED] = [callback1, callback2, callback3]
				raise StandardError.new("Test error")
			end
			
			adapter_with_callbacks = subject.new(app_with_callbacks)
			response = adapter_with_callbacks.call(request)
			
			# Callbacks should be invoked in reverse order: 3, 2, 1
			expect(call_order).to be == [3, 2, 1]
			expect(response.status).to be == 500
		end
		
		it "handles errors from callbacks gracefully and continues invoking other callbacks" do
			call_order = []
			
			callback1 = proc do |env, status, headers, error|
				call_order << 1
			end
			
			callback2 = proc do |env, status, headers, error|
				call_order << 2
				raise StandardError.new("Callback error")
			end
			
			callback3 = proc do |env, status, headers, error|
				call_order << 3
			end
			
			app_with_callbacks = proc do |env|
				env[Protocol::Rack::RACK_RESPONSE_FINISHED] = [callback1, callback2, callback3]
				raise StandardError.new("Test error")
			end
			
			adapter_with_callbacks = subject.new(app_with_callbacks)
			
			response = adapter_with_callbacks.call(request)
			
			# All callbacks should be invoked despite callback2 raising an error:
			# Callbacks should be invoked in reverse order: 3, 2, 1
			expect(call_order).to be == [3, 2, 1]
			expect(response.status).to be == 500
			
			# Verify that the error was logged:
			expect_console.to have_logged(
				severity: be == :error,
				subject: be == adapter_with_callbacks,
				message: be =~ /Error occurred during response finished callback:/
			)
		end
	end
end
