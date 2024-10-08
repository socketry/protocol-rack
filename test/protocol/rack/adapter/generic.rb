# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2024, by Samuel Williams.

require "protocol/rack/adapter/generic"
require "protocol/http/request"

require "disable_console_context"

describe Protocol::Rack::Adapter::Generic do
	let(:app) {->(env){[200, {}, []]}}
	let(:adapter) {subject.wrap(app)}
	
	it "can instantiate an adapter" do
		expect(adapter).not.to be_nil
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
	
	with "a app that returns nil" do
		include DisableConsoleContext
		
		let(:app) {->(env){nil}}
		let(:request) {Protocol::HTTP::Request["GET", "/", {"content-type" => "text/plain"}, nil]}
		
		it "can generate a failure response" do
			response = adapter.call(request)
			expect(response.status).to be == 500
			expect(response.read).to be == "ArgumentError: Status must be an integer!"
		end
	end
end
