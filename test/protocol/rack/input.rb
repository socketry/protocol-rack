# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2025, by Samuel Williams.
# Copyright, 2023, by Genki Takiuchi.

require "protocol/rack/input"
require "protocol/http/body/buffered"

describe Protocol::Rack::Input do
	let(:input) {subject.new(body)}
	
	with "body" do
		let(:sample_data) {%w{The quick brown fox jumped over the lazy dog}}
		let(:body) {Protocol::HTTP::Body::Buffered.new(sample_data)}
		
		it "can close input body" do
			expect(body).to receive(:close)
			input.close
			
			expect(input).to be(:empty?)
		end

		with "#read(length, buffer)" do
			let(:buffer) {String.new}
			let(:expected_output) {sample_data.join}
			
			it "can read partial input" do
				expect(input.read(3, buffer)).to be == "The"
				expect(buffer).to be == "The"
			end
			
			it "can read all input" do
				expect(input.read(expected_output.bytesize, buffer)).to be == expected_output
				expect(buffer).to be == expected_output
				
				expect(input.read(expected_output.bytesize, buffer)).to be == nil
				expect(buffer).to be == ""
				
				expect(input.read).to be == ""
				expect(input.read(1)).to be == nil
			end
		end
		
		with "#read" do
			it "can read all input" do
				expect(body).to receive(:close)
				
				expect(input.read).to be == sample_data.join
				expect(input.read).to be == ""
				
				expect(input).to be(:closed?)
			end
			
			it "can rewind after reading all input" do
				expect(input.read).to be == sample_data.join
				expect(input).to be(:closed?)
				
				input.rewind
				
				expect(input).not.to be(:closed?)
				expect(input.read).to be == sample_data.join
			end
			
			it "can read exactly the content length" do
				expect(body).to receive(:close)
				
				expect(input.read(sample_data.join.bytesize)).to be == sample_data.join
			end
			
			it "can read no input" do
				expect(input.read(0)).to be == ""
			end
			
			it "can read partial input" do
				expect(input.read(3)).to be == "The"
				expect(input.read(3)).to be == "qui"
				expect(input.read(3)).to be == "ckb"
				expect(input.read(3)).to be == "row"
			end
			
			it "can rewind after reading partial input" do
				expect(input.read(3)).to be == "The"
				expect(input).not.to be(:closed?)
				
				input.rewind
				
				expect(input).not.to be(:closed?)
				expect(input.read(3)).to be == "The"
			end
			
			it "can read all input" do
				expect(input.read(15)).to be == sample_data.join[0...15]
				expect(input.read).to be == sample_data.join[15..-1]
				
				expect(input.read(1)).to be == nil
				
				expect(input).to be(:closed?)
			end
			
			it "can read partial input with buffer" do
				buffer = String.new
				
				expect(input.read(3, buffer)).to be == "The"
				expect(input.read(3, buffer)).to be == "qui"
				expect(input.read(3, buffer)).to be == "ckb"
				expect(input.read(3, buffer)).to be == "row"
				
				expect(buffer).to be == "row"
			end
			
			it "can read all input with buffer" do
				buffer = String.new
				
				data = input.read(15, buffer)
				expect(data).to be == sample_data.join[0...15]
				expect(buffer).to be == data
				
				expect(input.read).to be == sample_data.join[15..-1]
				
				expect(input.read(1, buffer)).to be == nil
				expect(buffer).to be == ""
			end
		end
		
		with "#gets" do
			let(:sample_data) {"The quick brown\nfox jumped over the lazy dog\n"}
			
			it "can read chunks" do
				sample_data.each_line do |line|
					expect(input.gets).to be == line
				end
				
				expect(input.gets).to be == nil
			end
			
			it "returns remainder after calling #read" do
				expect(input.read(4)).to be == "The "
				expect(input.gets).to be == "quick brown\n"
				expect(input.read(4)).to be == "fox "
				expect(input.gets).to be == "jumped over the lazy dog\n"
			end
		end
		
		with "#each" do
			it "can read chunks" do
				input.each.with_index do |chunk, index|
					expect(chunk).to be == sample_data[index]
				end
			end
		end
		
		with "#closed?" do
			it "should not be at end of file" do
				expect(input).not.to be(:closed?)
			end
		end
	end
	
	with "no body" do
		let(:input) {subject.new(nil)}
		
		with "#read(length, buffer)" do
			let(:buffer) {String.new}
			
			it "can read no input" do
				expect(input.read(0, buffer)).to be == ""
				expect(buffer).to be == ""
			end
			
			it "can read partial input" do
				expect do
					input.read(2, buffer)
				end.not.to raise_exception(IOError)
				expect(buffer).to be == ""
			end
			
			it "can not read closed input" do
				expect do
					input.close
					input.read(2, buffer)
				end.to raise_exception(IOError)
				expect(buffer).to be == ""
			end
		end
		
		with "#each" do
			it "can read no input" do
				expect(input.each.to_a).to be == []
			end
		end
		
		it "should be closed" do
			expect(input).to be(:closed?)
		end
	end
end
