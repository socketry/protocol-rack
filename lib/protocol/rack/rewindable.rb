# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022, by Samuel Williams.

require 'protocol/http/body/rewindable'
require 'protocol/http/middleware'

module Protocol
	module Rack
		# Content-type driven input buffering, specific to the needs of `rack`.
		class Rewindable < ::Protocol::HTTP::Middleware
			# Media types that require buffering.
			BUFFERED_MEDIA_TYPES = %r{
				application/x-www-form-urlencoded|
				multipart/form-data|
				multipart/related|
				multipart/mixed
			}x
			
			POST = 'POST'
			
			# Initialize the rewindable middleware.
			# @parameter app [Protocol::HTTP::Middleware] The middleware to wrap.
			def initialize(app)
				super(app)
			end
			
			# Determine whether the request needs a rewindable body.
			# @parameter request [Protocol::HTTP::Request]
			# @returns [Boolean]
			def needs_rewind?(request)
				content_type = request.headers['content-type']
				
				if request.method == POST and content_type.nil?
					return true
				end
				
				if BUFFERED_MEDIA_TYPES =~ content_type
					return true
				end
				
				return false
			end
			
			def make_environment(request)
				@delegate.make_environment(request)
			end
			
			# Wrap the request body in a rewindable buffer if required.
			# @parameter request [Protocol::HTTP::Request]
			# @returns [Protocol::HTTP::Response] the response.
			def call(request)
				if body = request.body and needs_rewind?(request)
					request.body = Protocol::HTTP::Body::Rewindable.new(body)
				end
				
				return super
			end
		end
	end
end
