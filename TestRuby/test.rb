require 'nokogiri'
require 'curb'
require 'json'


$xmlresponsearray= Array.new
$outputFile = File.open("../output/Location_results#{Time.now.strftime("%Y%m%d")}.txt", 'w')
add_XML = "../input/provider_Add.xml"

$failed = Array.new
$passed = Array.new

class MyDocument < Nokogiri::XML::SAX::Document
$xmlresponsearray = Array.new

	def initialize
	end
	def end_document
		puts "The document has ended"
	end
	def start_element(name, attributes = [])
		@fields = [attributes[0][1]] if name == 'Provider'
		@last_seen_tag = name
		
		@location=[attributes[0][1]] if name == 'MOC_status'
	end
	def start_document
		puts "starting processing"
	end
	
	def characters(string)
			if ['phn_nmbr'].include? @last_seen_tag
			@fields << string
			
			end
		   if ['Location'].include? @last_seen_tag
			   @fields << @location[0]
			   		
		  end
	end
	def end_element name
		@last_seen_tag = nil
		$xmlresponsearray << @fields if name == 'Provider'
		
		
	end
	def end_document
		puts "ending processing"
	end

end

def countParaseXML(input_file)
# Counts records from xlm file, ask for sample size, and loads array with values from xml
puts "Counting #{input_file} as input file. Please wait..."
parser = Nokogiri::XML::SAX::Parser.new(MyDocument.new)
parser.parse(File.open(input_file))

 puts "What size sample would you like to test? (input a number 0-#{$xmlresponsearray.count})"

 print $xmlresponsearray
 return 0
end

	samplesize=countParaseXML(add_XML)