# Releases

## Unreleased

  - 100% test and documentation coverage.
  - {Protocol::Rack::Input#rewind} now works when the entire input is already read.
  - {Protocol::Rack::Adapter::Rack2} has stricter validation of the application response.
  
## v0.12.0

  - Ignore (and close) response bodies for status codes that don't allow them.

## v0.11.2

  - Stop setting `env["SERVER_PORT"]` to `nil` if not present.
