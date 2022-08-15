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

require 'protocol/rack/response'

describe Protocol::Rack::Response do
	with 'multiple set-cookie headers' do
		let(:response) {subject.wrap(200, {'set-cookie' => ["a", "b"]}, [])}
		let(:fields) {response.headers.fields}
		
		it "should generate multiple headers" do
			expect(fields).to be(:include?, ['set-cookie', 'a'])
			expect(fields).to be(:include?, ['set-cookie', 'b'])
		end
	end
	
	with '#to_path' do
		let(:body) {Array.new}
		
		it "should generate file body" do
			expect(body).to receive(:to_path).and_return("/dev/null")
			
			response = subject.wrap(200, {}, body)
			
			expect(response.body).to be(:kind_of?, Protocol::HTTP::Body::File)
		end
		
		it "should not modify partial responses" do
			response = subject.wrap(206, {}, body)
			
			expect(response.body).to be(:kind_of?, Protocol::Rack::Body::Enumerable)
		end
	end
	
	with 'with content-length' do
		it "should remove header" do
			response = subject.wrap(200, {'content-length' => '4'}, ["1234"])
			
			expect(response.headers).not.to be(:include?, 'content-length')
		end
	end
end
