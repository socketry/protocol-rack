# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022, by Samuel Williams.

require 'protocol/rack/body/streaming'

describe Protocol::Rack::Body::Streaming do
	with 'block' do
		let(:block) {proc{|stream| stream.write("Hello World")}}
		let(:body) {subject.new(block)}
		
		it "should wrap block" do
			expect(body.block).to be == block
		end
	end
end
