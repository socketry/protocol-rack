# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2024, by Samuel Williams.

require "sus/fixtures/console"
require "protocol/rack/response"

describe Protocol::Rack::Response do
	include Sus::Fixtures::Console::CapturedLogger
	
	let(:env) {Hash.new}
	let(:status) {200}
	let(:headers) {Hash.new}
	let(:meta) {Hash.new}
	let(:body) {Array.new}
	
	let(:response) {subject.wrap(env, status, Protocol::HTTP::Headers[headers], meta, body)}
	
	with "hop headers" do
		let(:headers) {{"connection" => "keep-alive", "keep-alive" => "timeout=10, max=100"}}
		
		include Sus::Fixtures::Console::CapturedLogger
		
		it "ignores hop headers" do
			expect(response.headers).not.to be(:include?, "connection")
			expect(response.headers).not.to be(:include?, "keep-alive")
			expect(response.headers).to be(:empty?)
			
			expect_console.to have_logged(message: be =~ /Ignoring hop headers/)
		end
	end
end
