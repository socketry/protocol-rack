# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2024, by Samuel Williams.

require "rack/lint"

require "protocol/rack/adapter"
require "disable_console_context"
require "server_context"

describe Protocol::Rack::Adapter do
	let(:rackup_path) {File.expand_path(".adapter/config.ru", __dir__)}
	
	it "can load rackup files" do
		expect(subject.parse_file(rackup_path)).to be_a(Proc)
	end
end

describe Protocol::Rack::Adapter::Generic do
	let(:adapter) {subject.new(lambda{})}
	
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
end

Adapter = Sus::Shared("an adapter") do
	include ServerContext
	
	let(:protocol) {subject}
	
	with "successful response" do
		let(:app) do
			Rack::Lint.new(
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
		include DisableConsoleContext
		
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
		it_behaves_like Adapter
	end
end
