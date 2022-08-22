# frozen_string_literal: true

# Copyright, 2022, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'disable_console_context'
require 'protocol/rack/adapter/rack3'

describe Protocol::Rack::Adapter::Rack3 do
	let(:app) {->(env) {[200, {}, []]}}
	let(:adapter) {subject.new(app)}
	
	let(:request) {Protocol::HTTP::Request.new('https', 'example.com', 'GET', '/', 'http/1.1', Protocol::HTTP::Headers[{'accept' => 'text/html'}], Protocol::HTTP::Body::Buffered.new)}
	let(:response) {adapter.call(request)}
	
	with 'set-cookie headers that has multiple values' do
		let(:app) {->(env) {[200, {'set-cookie' => ['a=b', 'x=y']}, []]}}
		
		it "can make a response newline separated headers" do
			expect(response.headers['set-cookie']).to be == ["a=b", "x=y"]
		end
	end
	
	with 'content-length header' do
		let(:app) {->(env) {[200, {'content-length' => '10'}, ["1234567890"]]}}
		
		it "removes content-length header" do
			expect(response.headers).not.to be(:include?, 'content-length')
		end
	end
	
	with 'connection: close header' do
		include DisableConsoleContext
		
		let(:app) {->(env) {[200, {'connection' => 'close'}, []]}}
		
		it "removes content-length header" do
			expect(response.headers).not.to be(:include?, 'connection')
		end
	end
	
	with 'body that responds to #to_path' do
		let(:body) {Array.new}
		let(:app) {->(env) {[200, {}, body]}}
	
		it "should generate file body" do
			expect(body).to receive(:to_path).and_return("/dev/null")
						
			expect(response.body).to be(:kind_of?, Protocol::HTTP::Body::File)
		end
	
		with '206 partial response status' do
			let(:app) {->(env) {[200, {}, body]}}
			
			it "should not modify partial responses" do
				expect(response.body).to be(:kind_of?, Protocol::Rack::Body::Enumerable)
			end
		end
	end
end
