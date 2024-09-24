# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2024, by Samuel Williams.

require "protocol/rack/response"
require "disable_console_context"

describe Protocol::Rack::Response do
	let(:env) {Hash.new}
	let(:status) {200}
	let(:headers) {Hash.new}
	let(:meta) {Hash.new}
	let(:body) {Array.new}
	
	let(:response) {subject.wrap(env, status, Protocol::HTTP::Headers[headers], meta, body)}
	
	with "hop headers" do
		include DisableConsoleContext
		
		let(:headers) {{"connection" => "keep-alive", "keep-alive" => "timeout=10, max=100"}}
		
		it "ignores hop headers" do
			expect(response.headers).not.to be(:include?, "connection")
			expect(response.headers).not.to be(:include?, "keep-alive")
			expect(response.headers).to be(:empty?)
		end
	end
end
