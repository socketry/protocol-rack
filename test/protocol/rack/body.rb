# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2025, by Samuel Williams.

require "sus/fixtures/console"
require "protocol/rack/body"
require "protocol/http/body/readable"
require "console"

describe Protocol::Rack::Body do
	include Sus::Fixtures::Console::CapturedLogger
	with "#no_content?" do
		it "returns true for status codes that indicate no content" do
			expect(subject.no_content?(204)).to be == true
			expect(subject.no_content?(205)).to be == true
			expect(subject.no_content?(304)).to be == true
			expect(subject.no_content?(200)).to be == false
		end
	end
	
	with "#wrap" do
		let(:env) {Hash.new}
		let(:headers) {Hash.new}
		
		it "handles nil body" do
			expect(Console).to receive(:warn).and_return(nil)
			
			result = subject.wrap(env, 200, headers, nil)
			expect(result).to be_nil
		end
		
		with "head request" do
			it "wraps response with content-length and empty body" do
				headers["content-length"] = "123"
				
				result = subject.wrap(env, 200, headers, [], nil, true)
				
				expect(result).to be_a(Protocol::HTTP::Body::Head)
				expect(result.length).to be == 123
			end
			
			it "wraps response with no content-length and empty body" do
				result = subject.wrap(env, 200, headers, [], nil, true)
				
				expect(result).to be_a(Protocol::HTTP::Body::Head)
				expect(result.length).to be == 0
			end
			
			it "wraps response with content-length and nil body" do
				headers["content-length"] = "123"
				
				expect(Console).to receive(:warn).and_return(nil)
				result = subject.wrap(env, 200, headers, nil, nil, true)
				
				expect(result).to be_a(Protocol::HTTP::Body::Head)
				expect(result.length).to be == 123
			end
			
			it "wraps response with no content-length and nil body" do
				expect(Console).to receive(:warn).and_return(nil)
				
				result = subject.wrap(env, 200, headers, nil, nil, true)
				
				expect(result).to be_nil
			end
			
			it "wraps response with content-length and body" do
				# We trust the appliation to provide the correct content-length, but this is usually validated at the transport layer.
				headers["content-length"] = "123"
				
				result = subject.wrap(env, 200, headers, ["body"], nil, true)
				
				expect(result).to be_a(Protocol::HTTP::Body::Head)
				expect(result.length).to be == 123
			end
		end
		
		with "non-empty body and no-content status" do
			let(:mock_body) do
				Protocol::HTTP::Body::Buffered.new(["content"])
			end
			
			[204, 205, 304].each do |status|
				it "closes body and returns nil for status #{status}", unique: status do
					expect(Console).to receive(:warn).and_return(nil)
					expect(mock_body).to receive(:close)
					
					result = subject.wrap(env, status, headers, mock_body)
					
					expect(result).to be_nil
				end
			end
		end
		
		with "empty body and no-content status" do
			let(:mock_body) do
				Protocol::HTTP::Body::Buffered.new
			end
			
			it "closes body and returns nil for no-content status" do
				expect(Console).not.to receive(:warn)
				expect(mock_body).to receive(:close)
				
				result = subject.wrap(env, 204, headers, mock_body)
				
				expect(result).to be_nil
			end
		end
		
		with "body and normal status" do
			let(:mock_body) do
				body = Object.new
				
				def body.each
					yield "content"
				end
				
				body
			end
			
			it "wraps body properly with status 200" do
				result = subject.wrap(env, 200, headers, mock_body)
				expect(result).to be_a(Protocol::Rack::Body::Enumerable)
				expect(result).not.to be_nil
			end
		end
		
		with "response finished callback" do
			it "returns a body that calls the callback when closed" do
				called = false
				
				callback = proc do
					called = true
				end
				
				env[Protocol::Rack::RACK_RESPONSE_FINISHED] = [callback]
				
				body = subject.wrap(env, 200, headers, ["body"], callback)
				
				expect(called).to be == false
				body.close
				expect(called).to be == true
			end
			
			it "calls the callback when the body is empty" do
				called = false
				
				callback = proc do
					called = true
				end
				
				env[Protocol::Rack::RACK_RESPONSE_FINISHED] = [callback]
				
				body = subject.wrap(env, 204, headers, [], callback)
				
				expect(body).to be_nil
				expect(called).to be == true
			end
			
			it "invokes callbacks in reverse order of registration" do
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
				
				env[Protocol::Rack::RACK_RESPONSE_FINISHED] = [callback1, callback2, callback3]
				
				body = subject.wrap(env, 200, headers, ["body"])
				body.close
				
				# Callbacks should be invoked in reverse order: 3, 2, 1
				expect(call_order).to be == [3, 2, 1]
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
				
				env[Protocol::Rack::RACK_RESPONSE_FINISHED] = [callback1, callback2, callback3]
				
				body = subject.wrap(env, 200, headers, ["body"])
				body.close
				
				# All callbacks should be invoked despite callback2 raising an error
				# Callbacks should be invoked in reverse order: 3, 2, 1
				expect(call_order).to be == [3, 2, 1]
				
				# Verify that the error was logged
				expect_console.to have_logged(
					severity: be == :error,
					subject: be == Protocol::Rack::Body,
					message: be =~ /Error occurred during response finished callback:/
				)
			end
			
			it "handles errors from callbacks when body is empty" do
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
				
				env[Protocol::Rack::RACK_RESPONSE_FINISHED] = [callback1, callback2, callback3]
				
				body = subject.wrap(env, 204, headers, [])
				
				expect(body).to be_nil
				
				# All callbacks should be invoked despite callback2 raising an error
				# Callbacks should be invoked in reverse order: 3, 2, 1
				expect(call_order).to be == [3, 2, 1]
				
				# Verify that the error was logged:
				expect_console.to have_logged(
					severity: be == :error,
					subject: be == Protocol::Rack::Body,
					message: be =~ /Error occurred during response finished callback:/
				)
			end
		end
	end
end
