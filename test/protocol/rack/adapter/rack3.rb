# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2025, by Samuel Williams.

require "sus/fixtures/console"

require "protocol/http/request"
require "protocol/rack/adapter/rack3"

describe Protocol::Rack::Adapter::Rack3 do
	include Sus::Fixtures::Console::CapturedLogger
	
	with "#call" do
		let(:app) {->(env) {[200, {}, []]}}
		let(:adapter) {subject.new(app)}
		
		let(:body) {Protocol::HTTP::Body::Buffered.new}
		let(:request) {Protocol::HTTP::Request.new("https", "example.com", "GET", "/", "http/1.1", Protocol::HTTP::Headers[{"accept" => "text/html"}], body)}
		let(:response) {adapter.call(request)}
		
		with "set-cookie headers that has multiple values" do
			let(:app) {->(env) {[200, {"set-cookie" => ["a=b", "x=y"]}, []]}}
			
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
			let(:fake_file) {Array.new}
			let(:app) {->(env) {[200, {}, fake_file]}}
			
			it "should generate file body" do
				expect(fake_file).to receive(:to_path).and_return("/dev/null")
				
				expect(response.body).to be(:kind_of?, Protocol::HTTP::Body::File)
			end
		
			with "206 partial response status" do
				let(:app) {->(env) {[200, {}, fake_file]}}
				
				it "should not modify partial responses" do
					expect(response.body).to be(:kind_of?, Protocol::Rack::Body::Enumerable)
				end
			end
		end
		
		with "a request that has response finished callbacks" do
			let(:callback) {->(env, status, headers, error){}}
			let(:app) {->(env) {env["rack.response_finished"] << callback; [200, {}, ["Hello World!"]]}}
			
			it "should call the callbacks" do
				expect(callback).to receive(:call)
				
				expect(response).to be(:success?)
				expect(response.read).to be == "Hello World!"
			end
		end
	end

	with "#make_response" do
		let(:env) {::Rack::MockRequest.env_for("/")}
		let(:response) {Protocol::HTTP::Response[200, headers: {}, body: []]}

		it "can wrap headers" do
			status, headers, body = subject.make_response(env, response)

			expect(status).to be == 200
			expect(headers).to be == {}
			expect(body).to be_a(Protocol::HTTP::Body::Buffered)
			expect(body).to be(:empty?)
		end
	end
end
