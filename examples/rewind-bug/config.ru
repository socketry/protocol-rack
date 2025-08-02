# typed: true
# frozen_string_literal: true

require "rack"

class BodyTestApp
	def call(env)
		# Get the request body
		body = env["rack.input"]
		
		# First read
		body.rewind
		first_read = body.read
		
		# Second read
		body.rewind
		second_read = body.read
		
		# Response showing both reads
		response_body = "First read: #{first_read.inspect}\n\nSecond read: #{second_read.inspect}"
		
		[200, { "Content-Type" => "text/plain" }, [response_body]]
	end
end

run BodyTestApp.new

## Output
#
# ➜ curl -X POST -d "This is test data" http://localhost:9292
# First read: "This is test data"
#
# Second read: ""%