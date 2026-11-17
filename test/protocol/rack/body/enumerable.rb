# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2026, by Samuel Williams.

require "protocol/rack/body/enumerable"

require "sus/fixtures/async/scheduler_context"

describe Protocol::Rack::Body::Enumerable do
	with "empty body" do
		let(:body) {subject.new([], nil)}
		
		it "should be empty?" do
			expect(body).to be(:empty?)
		end
	end
	
	with "single string body" do
		let(:body) {subject.new(["Hello World"], nil)}
		
		it "should not be empty?" do
			expect(body).not.to be(:empty?)
		end
	end
	
	with "#read" do
		let(:body) {subject.new(["Hello", " ", "World"], 11)}
		
		it "returns chunks in order" do
			expect(body.read).to be == "Hello"
			expect(body.read).to be == " "
			expect(body.read).to be == "World"
			expect(body.read).to be_nil
			expect(body.read).to be_nil
		end
		
		it "returns nil when exhausted" do
			body.read
			body.read
			body.read
			expect(body.read).to be_nil
		end
		
		it "returns nil to the body from each yield" do
			values = []
			body = subject.new(Class.new{define_method(:each){|&block| values << block.call("Hello")}}.new, 5)
			
			expect(body.read).to be == "Hello"
			expect(body.read).to be_nil
			expect(values).to be == [nil]
		end
		
		it "can be read from different fibers" do
			expect(body.read).to be == "Hello"
			expect(Fiber.new{body.read}.resume).to be == " "
			expect(body.read).to be == "World"
		end
		
		it "closes the wrapped body when closed partway through" do
			closed = false
			body = subject.new(Rack::BodyProxy.new(["Hello", " ", "World"]){closed = true}, 11)
			
			expect(body.read).to be == "Hello"
			body.close
			
			expect(closed).to be == true
		end
		
		with "a body that raises" do
			let(:failing) do
				Class.new do
					def each
						yield "Hello"
						raise "Bad Enumerable"
					end
				end
			end
			
			let(:body) {subject.new(failing.new, nil)}
			
			include Sus::Fixtures::Async::SchedulerContext
			
			it "raises the error to the reader" do
				expect(body.read).to be == "Hello"
				expect{body.read}.to raise_exception(RuntimeError, message: be =~ /Bad Enumerable/)
			end
			
			it "enumerates the body again after the error" do
				body.read
				expect{body.read}.to raise_exception(RuntimeError)
				
				expect(body.read).to be == "Hello"
			end
		end
		
		with "a body that raises StopIteration" do
			let(:stopping) do
				Class.new do
					def each
						yield "Hello"
						raise StopIteration
					end
				end
			end
			
			let(:body) {subject.new(stopping.new, nil)}
			
			it "treats it as the end of the body" do
				expect(body.read).to be == "Hello"
				expect(body.read).to be_nil
				
				expect(body.read).to be == "Hello"
			end
		end
		
		with "a body that raises an exception that is not a StandardError" do
			let(:failing) do
				Class.new do
					def each
						yield "Hello"
						raise Interrupt
					end
				end
			end
			
			let(:body) {subject.new(failing.new, nil)}
			
			include Sus::Fixtures::Async::SchedulerContext
			
			it "raises the exception to the reader" do
				expect(body.read).to be == "Hello"
				expect{body.read}.to raise_exception(Interrupt)
			end
		end
		
		with "a body that yields from a nested fiber" do
			let(:nested) do
				Class.new do
					def each(&block)
						Fiber.new do
							block.call("Hello")
							block.call(" ")
						end.resume
						
						block.call("World")
					end
				end
			end
			
			let(:body) {subject.new(nested.new, 11)}
			
			it "returns every chunk" do
				expect(body.read).to be == "Hello"
				expect(body.read).to be == " "
				expect(body.read).to be == "World"
				expect(body.read).to be_nil
			end
		end
	end
	
	with "#each" do
		let(:bad_enumerable) do
			Enumerator.new do |yielder|
				raise "Bad Enumerable"
			end
		end
		
		let(:body) {subject.new(bad_enumerable, 1)}
		
		it "closes the body when the block raises an error" do
			expect(body).to receive(:close)
			
			expect do
				body.each do |chunk|
					# Ignore...
				end
			end.to raise_exception(RuntimeError, message: be =~ /Bad Enumerable/)
		end
		
		it "does not enumerate after being closed" do
			body = subject.new(["Hello World"], 11)
			body.close
			
			chunks = []
			body.each{|chunk| chunks << chunk}
			
			expect(chunks).to be(:empty?)
		end
	end
	
	with "#call" do
		let(:bad_callable) do
			proc do |stream|
				raise "Bad Callable"
			end
		end
		
		let(:body) {subject.new(bad_callable, 1)}
		
		it "streams the body" do
			expect(body).to receive(:close)
			
			expect do
				body.call(nil)
			end.to raise_exception(RuntimeError, message: be =~ /Bad Callable/)
		end
	end
	
	with ".wrap" do
		it "calls close on body proxy" do
			closed = false
			rack_body = Rack::BodyProxy.new(["Hello", "World"]) do
				closed = true
			end
			
			wrapped = subject.wrap(rack_body)
			
			# Consume the body
			chunks = []
			wrapped.each{|chunk| chunks << chunk}
			
			# The close callback should have been called
			expect(closed).to be == true
		end
	end
end
