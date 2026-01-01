# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2025, by Samuel Williams.

require "protocol/rack/request"
require "protocol/rack/adapter"

describe Protocol::Rack::Request do
	let(:app) {proc{|env| [200, {}, []]}}
	let(:adapter) {Protocol::Rack::Adapter.new(app)}
	
	let(:headers) {Protocol::HTTP::Headers[{"accept" => "text/html"}]}
	let(:body) {Protocol::HTTP::Body::Buffered.new}
	
	let(:request) {Protocol::HTTP::Request.new("https", "example.com", "GET", "/", "HTTP/1.1", headers, body)}
	
	let(:env) {adapter.make_environment(request)}
	
	let(:wrapped_request) {subject.new(env)}
	
	with "incoming rack env" do
		it "can restore request from original request" do
			expect(subject[env]).to be == request
		end
		
		it "can regenerate request from generic env" do
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
	
	with "incoming rack env which includes HTTP upgrade" do
		let(:headers) {Protocol::HTTP::Headers[{"upgrade" => "websocket"}]}
		
		it "can extract upgrade request" do
			expect(wrapped_request).to have_attributes(
				protocol: be == ["websocket"]
			)
		end
	end
	
	with "incoming rack env which includes rack.protocol" do
		let(:request) {Protocol::HTTP::Request.new("https", "example.com", "GET", "/", "HTTP/1.1", headers, body, ["websocket"])}
		
		it "can extract upgrade request" do
			expect(env).to have_keys(
				"HTTP_UPGRADE" => be == "websocket",
			)
			
			expect(wrapped_request).to have_attributes(
				protocol: be == ["websocket"]
			)
		end
	end
	
	with "incoming request with both host header and authority" do
		let(:headers) {Protocol::HTTP::Headers[{"host" => "header.example.com"}]}
		let(:request) {Protocol::HTTP::Request.new("https", "authority.example.com", "GET", "/", "HTTP/1.1", headers, body)}
		
		it "correctly sets HTTP_HOST to the authority instead of host header" do
			# According to HTTP/2 semantics, :authority should take precedence over the host header when both are present:
			expect(env).to have_keys(
				"HTTP_HOST" => be == "authority.example.com"
			)
		end
	end
	
	with "incoming request with trailing host header" do
		let(:headers) {Protocol::HTTP::Headers.new([["host", "header.example.com"]], 0)}
		let(:request) {Protocol::HTTP::Request.new("https", nil, "GET", "/", "HTTP/1.1", headers, body)}
		
		it "rejects the request" do
			expect(env).not.to have_keys("HTTP_HOST")
		end
	end
end
