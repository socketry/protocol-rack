# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2024, by Samuel Williams.

require "protocol/rack/body/enumerable"

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
	end
end
