# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2025, by Samuel Williams.

require "protocol/rack/adapter/rack2"

require "sus/fixtures/console"

require "rack"
require "protocol/rack/body/streaming"

describe Protocol::Rack::Adapter::Rack2 do
	include Sus::Fixtures::Console::CapturedLogger
	
	with "#call" do
		let(:app) {->(env) {[200, {}, []]}}
		let(:adapter) {subject.new(app)}
		
		let(:body) {Protocol::HTTP::Body::Buffered.new}
		let(:request) {Protocol::HTTP::Request.new("https", "example.com", "GET", "/", "http/1.1", Protocol::HTTP::Headers[{"accept" => "text/html"}], body)}
		let(:response) {adapter.call(request)}
		
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

	with "#make_response" do
		let(:env) {::Rack::MockRequest.env_for("/")}

		it "can wrap response" do
			response = Protocol::HTTP::Response[200, headers: {}, body: []]
			status, headers, body = subject.make_response(env, response)

			expect(status).to be == 200
			expect(headers).to be == {}
			expect(body).to be_a(Protocol::HTTP::Body::Buffered)
			expect(body).to be(:empty?)
		end


		it "can wrap streaming response" do
			streaming_body = Protocol::Rack::Body::Streaming.new(->(stream){})
			response = Protocol::HTTP::Response[200, headers: {}, body: streaming_body]

			env[Protocol::Rack::RACK_IS_HIJACK] = true

			status, headers, body = subject.make_response(env, response)

			expect(status).to be == 200
			expect(headers).to have_keys(Protocol::Rack::RACK_HIJACK)
			expect(body).to be == []
		end
	end
end