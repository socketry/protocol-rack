# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2024, by Samuel Williams.

require "protocol/rack/adapter"

describe Protocol::Rack::Adapter do
	let(:rackup_path) {File.expand_path(".adapter/config.ru", __dir__)}
	
	it "can load rackup files" do
		expect(subject.parse_file(rackup_path)).to be_a(Proc)
	end
end
