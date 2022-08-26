# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022, by Samuel Williams.

require 'protocol/rack/request'
require 'protocol/rack/adapter'

describe Protocol::Rack::Request do
	let(:app) {proc{|env| [200, {}, []]}}
	let(:adapter) {Protocol::Rack::Adapter.new(app)}
	
	with 'incoming rack env' do
		let(:body) {Protocol::HTTP::Body::Buffered.new}
		
		let(:request) {Protocol::HTTP::Request.new(
			'https', 'example.com', 'GET', '/', 'http/1.1', Protocol::HTTP::Headers[{'accept' => 'text/html'}], body
		)}
		
		let(:env) {adapter.make_environment(request)}
		
		it "can restore request from original request" do
			expect(subject[env]).to be == request
		end
		
		it "can regenerate request from generic env" do
			env.delete(Protocol::Rack::PROTOCOL_HTTP_REQUEST)
			
			wrapped_request = subject[env]
			
			expect(wrapped_request.scheme).to be == request.scheme
			expect(wrapped_request.authority).to be == request.authority
			expect(wrapped_request.method).to be == request.method
			expect(wrapped_request.path).to be == request.path
			expect(wrapped_request.version).to be == request.version
			expect(wrapped_request.headers.to_h).to be == request.headers.to_h
			expect(wrapped_request.body.join).to be == request.body.join
			expect(wrapped_request.protocol).to be == request.protocol
		end
	end
end
