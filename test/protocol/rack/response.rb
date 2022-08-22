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
require 'disable_console_context'

describe Protocol::Rack::Response do
	let(:status) {200}
	let(:headers) {Hash.new}
	let(:meta) {Hash.new}
	let(:body) {Array.new}
	
	let(:response) {subject.wrap(status, Protocol::HTTP::Headers[headers], meta, body)}
	
	with 'hop headers' do
		include DisableConsoleContext
		
		let(:headers) {{'connection' => 'keep-alive', 'keep-alive' => 'timeout=10, max=100'}}
		
		it 'ignores hop headers' do
			expect(response.headers).not.to be(:include?, 'connection')
			expect(response.headers).not.to be(:include?, 'keep-alive')
			expect(response.headers).to be(:empty?)
		end
	end
end
