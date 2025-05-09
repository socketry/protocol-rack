# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2024, by Samuel Williams.

require "protocol/rack/rewindable"
require "protocol/http/body/rewindable"

describe Protocol::Rack::Rewindable do
	let(:headers) {Protocol::HTTP::Headers.new}
	let(:body) {Protocol::HTTP::Body::Readable.new}
	let(:app) {
		app = Object.new
		mock(app) do |mock|
			mock.replace(:call) do |request|
				Protocol::HTTP::Response[200, {}, []]
			end
		end
		app
	}
	
	with "non-POST requests" do
		it "should rewind if it has a buffered media type" do
			request = Protocol::HTTP::Request.new(
				"https", "example.com", "GET", "/", "HTTP/1.1", headers, body
			)
			request.headers["content-type"] = "application/x-www-form-urlencoded"
			
			rewindable = subject.new(nil)
			expect(rewindable.needs_rewind?(request)).to be == true
		end
	end
	
	with "POST requests" do
		it "should rewind POST requests with no content type" do
			request = Protocol::HTTP::Request.new(
				"https", "example.com", "POST", "/", "HTTP/1.1", headers, body
			)
			
			rewindable = subject.new(nil)
			expect(rewindable.needs_rewind?(request)).to be == true
		end
		
		it "should rewind form-urlencoded requests" do
			request = Protocol::HTTP::Request.new(
				"https", "example.com", "POST", "/", "HTTP/1.1", headers, body
			)
			request.headers["content-type"] = "application/x-www-form-urlencoded"
			
			rewindable = subject.new(nil)
			expect(rewindable.needs_rewind?(request)).to be == true
		end
		
		it "should rewind multipart form requests" do
			request = Protocol::HTTP::Request.new(
				"https", "example.com", "POST", "/", "HTTP/1.1", headers, body
			)
			request.headers["content-type"] = "multipart/form-data; boundary=----WebKitFormBoundary"
			
			rewindable = subject.new(nil)
			expect(rewindable.needs_rewind?(request)).to be == true
		end
		
		it "should rewind multipart related requests" do
			request = Protocol::HTTP::Request.new(
				"https", "example.com", "POST", "/", "HTTP/1.1", headers, body
			)
			request.headers["content-type"] = "multipart/related; boundary=----WebKitFormBoundary"
			
			rewindable = subject.new(nil)
			expect(rewindable.needs_rewind?(request)).to be == true
		end
		
		it "should rewind multipart mixed requests" do
			request = Protocol::HTTP::Request.new(
				"https", "example.com", "POST", "/", "HTTP/1.1", headers, body
			)
			request.headers["content-type"] = "multipart/mixed; boundary=----WebKitFormBoundary"
			
			rewindable = subject.new(nil)
			expect(rewindable.needs_rewind?(request)).to be == true
		end
		
		it "should not rewind other content types" do
			request = Protocol::HTTP::Request.new(
				"https", "example.com", "POST", "/", "HTTP/1.1", headers, body
			)
			request.headers["content-type"] = "application/json"
			
			rewindable = subject.new(nil)
			expect(rewindable.needs_rewind?(request)).to be == false
		end
	end
	
	with "body wrapping" do
		it "should wrap rewindable bodies" do
			request = Protocol::HTTP::Request.new(
				"https", "example.com", "POST", "/", "HTTP/1.1", headers, body
			)
			request.headers["content-type"] = "application/x-www-form-urlencoded"
			
			rewindable = subject.new(app)
			rewindable.call(request)
			
			expect(request.body).to be_a(Protocol::HTTP::Body::Rewindable)
			expect(request.body.body).to be == body
		end
		
		it "should not wrap non-rewindable bodies" do
			request = Protocol::HTTP::Request.new(
				"https", "example.com", "POST", "/", "HTTP/1.1", headers, body
			)
			request.headers["content-type"] = "application/json"
			
			rewindable = subject.new(app)
			rewindable.call(request)
			
			expect(request.body).to be == body
		end
	end
	
	with "middleware delegation" do
		it "should delegate make_environment to wrapped middleware" do
			request = Protocol::HTTP::Request.new(
				"https", "example.com", "POST", "/", "HTTP/1.1", headers, body
			)
			env = {"rack.input" => StringIO.new}
			
			middleware = Object.new
			mock(middleware) do |mock|
				mock.replace(:make_environment) do |request|
					env
				end
			end
			
			rewindable = subject.new(middleware)
			expect(rewindable.make_environment(request)).to be == env
		end
	end
end 