# frozen_string_literal: true

require_relative "lib/protocol/rack/version"

Gem::Specification.new do |spec|
	spec.name = "protocol-rack"
	spec.version = Protocol::Rack::VERSION
	
	spec.summary = "An implementation of the Rack protocol/specification."
	spec.authors = ["Samuel Williams"]
	spec.license = "MIT"
	
	spec.cert_chain  = ['release.cert']
	spec.signing_key = File.expand_path('~/.gem/release.pem')
	
	spec.homepage = "https://github.com/socketry/protocol-rack"
	
	spec.files = Dir.glob(['{lib}/**/*', '*.md'], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 2.5"
	
	spec.add_dependency "protocol-http", "~> 0.23.4"
	spec.add_dependency "rack", ">= 1.0"
	
	spec.add_development_dependency "async-http", "~> 0.59"
	spec.add_development_dependency "bake-test"
	spec.add_development_dependency "bake-test-external"
	spec.add_development_dependency "covered"
	spec.add_development_dependency "sus", "~> 0.10.0"
	spec.add_development_dependency "sus-fixtures-async-http", "~> 0.1.1"
end
