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

require 'protocol/rack/request'
require 'protocol/rack/adapter'

describe Protocol::Rack::Request do
	let(:app) {proc{|env| [200, {}, []]}}
	let(:adapter) {Protocol::Rack::Adapter.new(app)}
	
	with 'incoming rack env' do
		let(:body) {Protocol::HTTP::Body::Buffered.new}
		
		let(:request) {Protocol::HTTP::Request.new(
			'https', 'example.com', 'GET', '/', 'http/1.1', Protocol::HTTP::Headers[{'accept' => 'text/html'}], body
		)}
		
		let(:env) {adapter.make_environment(request)}
		
		it "can restore request from original request" do
			expect(subject[env]).to be == request
		end
		
		it "can regenerate request from generic env" do
			env.delete(Protocol::Rack::PROTOCOL_HTTP_REQUEST)
			
			wrapped_request = subject[env]
			
			expect(wrapped_request.scheme).to be == request.scheme
			expect(wrapped_request.authority).to be == request.authority
			expect(wrapped_request.method).to be == request.method
			expect(wrapped_request.path).to be == request.path
			expect(wrapped_request.version).to be == request.version
			expect(wrapped_request.headers.to_h).to be == request.headers.to_h
			expect(wrapped_request.body.join).to be == request.body.join
			expect(wrapped_request.protocol).to be == request.protocol
		end
	end
end
