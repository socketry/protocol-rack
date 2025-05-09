# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2024, by Samuel Williams.

require "sus/fixtures/console"
require "protocol/rack/an_adapter"
require "protocol/rack/adapter/rack2"

describe Protocol::Rack::Adapter::Rack2 do
	include Sus::Fixtures::Console::CapturedLogger
	
	let(:app) {->(env) {[200, {}, []]}}
	let(:adapter) {subject.new(app)}
	
	let(:body) {Protocol::HTTP::Body::Buffered.new}
	let(:request) {Protocol::HTTP::Request.new("https", "example.com", "GET", "/", "http/1.1", Protocol::HTTP::Headers[{"accept" => "text/html"}], body)}
	let(:response) {adapter.call(request)}
	
	it_behaves_like Protocol::Rack::AnAdapter
	
	with "set-cookie headers that has multiple values" do
		let(:app) {->(env) {[200, {"set-cookie" => "a=b\nx=y"}, []]}}
		
		it "can make a response newline separated headers" do
			expect(response.headers["set-cookie"]).to be == ["a=b", "x=y"]
		end
	end
	
	with "content-length header" do
		let(:app) {->(env) {[200, {"content-length" => "10"}, ["1234567890"]]}}
		
		it "removes content-length header" do
			expect(response.headers).not.to be(:include?, "content-length")
		end
	end
	
	with "connection: close header" do
		let(:app) {->(env) {[200, {"connection" => "close"}, []]}}
		
		it "removes content-length header" do
			expect(response.headers).not.to be(:include?, "connection")
		end
	end
	
	with "body that responds to #to_path" do
		let(:body) {Array.new}
		let(:app) {->(env) {[200, {}, body]}}
	
		it "should generate file body" do
			expect(body).to receive(:to_path).and_return("/dev/null")
						
			expect(response.body).to be_a(Protocol::HTTP::Body::File)
		end
	
		with "206 partial response status" do
			let(:app) {->(env) {[200, {}, body]}}
			
			it "should not modify partial responses" do
				expect(response.body).to be_a(Protocol::Rack::Body::Enumerable)
			end
		end
	end
	
	with "a hijacked response" do
		let(:callback) {->(stream){}}
		let(:app) {->(env){[200, {"rack.hijack" => callback}, []]}}
		
		it "should support hijacking" do
			expect(response.body).to be_a(Protocol::Rack::Body::Streaming)
		end
	end
	
	with "response handling" do
		with "array response" do
			let(:app) {->(env) {[200, {}, ["Hello"]]}}
			
			it "handles array response correctly" do
				expect(response.body).to be_a(Protocol::Rack::Body::Enumerable)
			end
		end
		
		with "string response" do
			let(:app) {->(env) {[200, {}, "Hello"]}}
			
			it "handles string response correctly" do
				expect(response.status).to be == 500
				expect(response.read).to be == "ArgumentError: Body must respond to #each!"
			end
		end
	end
	
	with "header transformation" do
		with "array values" do
			let(:app) {->(env) {[200, {"x-custom" => "a\nb"}, []]}}
			
			it "joins array values with newlines in response" do
				expect(response.headers["x-custom"]).to be == ["a", "b"]
			end
		end
		
		with "non-array values" do
			let(:app) {->(env) {[200, {"x-custom" => "value"}, []]}}
			
			it "preserves non-array values" do
				expect(response.headers["x-custom"]).to be == ["value"]
			end
		end
		
		with "multiple set-cookie headers" do
			let(:app) {->(env) {[200, {"set-cookie" => "a=b\nx=y"}, []]}}
			
			it "joins set-cookie headers with newlines" do
				expect(response.headers["set-cookie"]).to be == ["a=b", "x=y"]
			end
		end
		
		with "rack specific headers" do
			let(:app) {->(env) {[200, {"rack.hijack" => ->(stream){}}, []]}}
			
			it "preserves rack specific headers in meta" do
				expect(response.headers).not.to be(:include?, "rack.hijack")
			end
		end
	end
end
