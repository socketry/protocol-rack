# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022, by Samuel Williams.

require 'protocol/rack/body/input_wrapper'

describe Protocol::Rack::Body::InputWrapper do
	with 'file' do
		let(:contents) {File.read(__FILE__)}
		let(:body) {subject.new(File.open(__FILE__, "r"), block_size: 128)}
		
		it "can read all contents" do
			expect(body.join).to be == contents
		ensure
			body.close
		end
		
		it "can read all contents in chunks" do
			chunks = []
			while chunk = body.read
				chunks << chunk
			end
			
			# Check we have a couple of chunks:
			expect(chunks.size).to be > 1
			
			expect(chunks.join).to be == contents
		ensure
			body.close
		end
	end
end
