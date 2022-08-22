# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :maintenance, optional: true do
	gem 'bake-modernize'
	gem 'bake-gem'
end

group :test do
	gem 'sus', '~> 0.10.0'
	gem 'bake-test'
	gem 'bake-test-external'
	
	gem 'async-http', "~> 0.59"
end
