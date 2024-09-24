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
end
