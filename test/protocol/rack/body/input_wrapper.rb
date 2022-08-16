# frozen_string_literal: true

# Copyright, 2018, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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
