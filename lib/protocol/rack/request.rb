# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022, by Samuel Williams.

require 'protocol/http/request'
require 'protocol/http/headers'

require_relative 'body/input_wrapper'

module Protocol
	module Rack
		class Request < ::Protocol::HTTP::Request
			def self.[](env)
				env['protocol.http.request'] ||= new(env)
			end

			def initialize(env)
				@env = env

				super(
					@env['rack.url_scheme'],
					@env['HTTP_HOST'],
					@env['REQUEST_METHOD'],
					@env['PATH_INFO'],
					@env['SERVER_PROTOCOL'],
					self.class.headers(@env),
					Body::InputWrapper.new(@env['rack.input']),
					self.class.protocol(@env)
				)
			end

			HTTP_UPGRADE = 'HTTP_UPGRADE'

			def self.protocol(env)
				if protocols = env['rack.protocol']
					return Array(protocols)
				elsif protocols = env[HTTP_UPGRADE]
					return protocols.split(/\s*,\s*/)
				end
			end

			def self.headers(env)
				headers = ::Protocol::HTTP::Headers.new
				env.each do |key, value|			
					if key.start_with?('HTTP_')
						next if key == 'HTTP_HOST'
						headers[key[5..-1].gsub('_', '-').downcase] = value
					end
				end

				return headers
			end
		end
	end
end
