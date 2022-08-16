# frozen_string_literal: true

# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require 'protocol/rack/adapter'
require 'server_context'

describe Protocol::Rack::Adapter do
	let(:adapter) {subject.new(lambda{})}
	
	with '#unwrap_headers' do
		let(:fields) {[['cookie', 'a=b'], ['cookie', 'x=y']]}
		let(:env) {Hash.new}
		
		it "should merge duplicate headers" do
			adapter.unwrap_headers(fields, env)
			
			expect(env).to be == {'HTTP_COOKIE' => "a=b;x=y"}
		end
	end

	with 'successful response'do
		include ServerContext
		let(:protocol) {Async::HTTP::Protocol::HTTP1}
		
		let(:app) do
			lambda do |env|
				[200, {}, ["Hello World!"]]
			end
		end
		
		let(:response) {client.get("/")}
		
		it "get valid HTTP_HOST" do
			expect(response.read).to be == "Hello World!"
		end
	end
	
	with 'HTTP_HOST' do
		include ServerContext
		let(:protocol) {Async::HTTP::Protocol::HTTP2}
		
		let(:app) do
			lambda do |env|
				[200, {}, ["HTTP_HOST: #{env['HTTP_HOST']}"]]
			end
		end
		
		let(:response) {client.get("/")}
		
		it "get valid HTTP_HOST" do
			expect(response.read).to be == "HTTP_HOST: 127.0.0.1:9294"
		end
	end
	
	# with 'connection: close', timeout: 1 do
	# 	include ServerContext
	# 	let(:protocol) {Async::HTTP::Protocol::HTTP1}
		
	# 	let(:app) do
	# 		lambda do |env|
	# 			[200, {'Connection' => 'close'}, ["Hello World!"]]
	# 		end
	# 	end
		
	# 	let(:response) {client.get("/")}
		
	# 	it "get valid response" do
	# 		expect(response.headers).to_not include('connection')
	# 		expect(response.read).to be == "Hello World!"
	# 	end
	# end
	
	# context 'REQUEST_URI', timeout: 1 do
	# 	include_context Falcon::Server
	# 	let(:protocol) {Async::HTTP::Protocol::HTTP2}
		
	# 	let(:app) do
	# 		lambda do |env|
	# 			[200, {}, ["REQUEST_URI: #{env['REQUEST_URI']}"]]
	# 		end
	# 	end
		
	# 	let(:response) {client.get("/?foo=bar")}
		
	# 	it "get valid REQUEST_URI" do
	# 		expect(response.read).to be == "REQUEST_URI: /?foo=bar"
	# 	end
	# end
	
	# context 'websockets', timeout: 1 do
	# 	include_context Falcon::Server
		
	# 	let(:endpoint) {Async::HTTP::Endpoint.parse('http://127.0.0.1:9294', reuse_port: true)}
		
	# 	let(:app) do
	# 		lambda do |env|
	# 			Async::WebSocket::Adapters::Rack.open(env) do |connection|
	# 				while message = connection.read
	# 					connection.write(message)
	# 				end
					
	# 				connection.close
	# 			end or [200, {}, []]
	# 		end
	# 	end
		
	# 	let(:test_message) do
	# 		{
	# 			user: "test",
	# 			status: "connected",
	# 		}
	# 	end
		
	# 	it "can send and receive messages using websockets" do
	# 		Async::WebSocket::Client.connect(endpoint) do |connection|
	# 			connection.write(test_message)
				
	# 			message = connection.read
	# 			expect(message).to be == test_message
	# 		end
	# 	end
	# end
	
	# context 'streaming' do
	# 	include_context Falcon::Server
		
	# 	let(:app) do
	# 		lambda do |env|
	# 			body = lambda do |stream|
	# 				stream.write("Hello Streaming World")
	# 				stream.close
	# 			end
				
	# 			[200, {}, body]
	# 		end
	# 	end
		
	# 	let(:response) {client.get("/")}
		
	# 	it "can read streaming response" do
	# 		expect(response.read).to be == "Hello Streaming World"
	# 	end
	# end
end
