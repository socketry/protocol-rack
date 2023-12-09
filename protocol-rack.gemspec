# frozen_string_literal: true

require_relative "lib/protocol/rack/version"

Gem::Specification.new do |spec|
	spec.name = "protocol-rack"
	spec.version = Protocol::Rack::VERSION
	
	spec.summary = "An implementation of the Rack protocol/specification."
	spec.authors = ["Samuel Williams", "Genki Takiuchi"]
	spec.license = "MIT"
	
	spec.cert_chain  = ['release.cert']
	spec.signing_key = File.expand_path('~/.gem/release.pem')
	
	spec.homepage = "https://github.com/socketry/protocol-rack"
	
	spec.files = Dir.glob(['{lib}/**/*', '*.md'], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 3.0"
	
	spec.add_dependency "protocol-http", "~> 0.23"
	spec.add_dependency "rack", ">= 1.0"
end
