# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2024, by Samuel Williams.

source "https://rubygems.org"

gemspec

group :maintenance, optional: true do
	gem 'bake-modernize'
	gem 'bake-gem'
	
	gem 'utopia-project'
end

group :test do
	gem "sus"
	gem "covered"
	gem "decode"
	gem "rubocop"
	
	gem "sus-fixtures-async-http", "~> 0.1"
	
	gem "bake-test", "~> 0.1"
	gem "bake-test-external", "~> 0.1"
end
