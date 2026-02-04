# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2024, by Samuel Williams.

require "protocol/rack/body/streaming"

require "sus/fixtures/async/scheduler_context"

describe Protocol::Rack::Body::Streaming do
	include Sus::Fixtures::Async::SchedulerContext
	
	let(:block) {proc{|stream| stream.write("Hello"); stream.write("World"); stream.close}}
	let(:body) {subject.new(block)}
	
	with "#read" do
		it "can read the body" do
			expect(body.read).to be == "Hello"
			expect(body.read).to be == "World"
			expect(body.read).to be == nil
		end
	end
	
	with "#each" do
		it "can read the body" do
			chunks = []
			body.each{|chunk| chunks << chunk}
			expect(chunks).to be == ["Hello", "World"]
		end
	end
	
	with "#call" do
		it "can read the body" do
			stream = StringIO.new
			body.call(stream)
			expect(stream.string).to be == "HelloWorld"
		end
	end
	
	with "nested fiber" do
		let(:block) do
			proc do |stream|
				Fiber.new do
					stream.write("Hello")
				end.resume
			end
		end
		
		it "can read a chunk" do
			expect(body.read).to be == "Hello"
		end
	end
	
	with "#close" do
		it "closes the wrapped body if it responds to close" do
			close_called = false
			wrapped_body = Object.new
			wrapped_body.define_singleton_method(:close) do
				close_called = true
			end
			wrapped_body.define_singleton_method(:call) do |stream|
				stream.write("Hello")
			end
			
			body = subject.new(wrapped_body)
			body.close
			
			expect(close_called).to be == true
		end
		
		it "does not fail if wrapped body does not respond to close" do
			wrapped_body = proc { |stream| stream.write("Hello") }
			
			body = subject.new(wrapped_body)
			body.close
		end
	end
end
