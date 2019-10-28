#parse the new providers file 

require 'nokogiri'
require 'curb'
require 'json'

$adds = Array.new
$deletes = Array.new
db_record = Array.new
web_record = Array.new
passed = Array.new
failed = Array.new
miss = Array.new
outputFile = File.open("../output/Provider_results#{Time.now.strftime("%Y%m%d")}.txt", 'a')
delete_XML = "../input/provider_Del.xml"
add_XML = "../input/provider_Add.xml"


class MyDocument < Nokogiri::XML::SAX::Document
	def initialize
	end
	def end_document
		puts "The document has ended"
	end
	def start_element(name, attributes = [])
		@fields = [attributes[0][1]] if name == 'Provider'
		@last_seen_tag = name
	end

	def characters(string)
		if ['Last_Name', 'First_Name', 'Gndr'].include? @last_seen_tag
			@fields << string
		end
	end
	def end_element name
		@last_seen_tag = nil
		$adds << @fields if name == 'Provider'
	end
end

def parse_del(input_file)
	puts "Parsing #{input_file} data. Please wait..."
	doc = Nokogiri::XML(File.read(input_file))
	doc.xpath("//Provider").each do |provider|
		$deletes << [provider["PAC_ID"]]
	end
end

puts "Parsing #{add_XML} as input file. Please wait..."
parser = Nokogiri::XML::SAX::Parser.new(MyDocument.new)
parser.parse(File.open(add_XML))
parse_del(delete_XML)
puts "#{$adds.count} total additions"
valid = false
until valid
	puts 'Enter the number for the environment you are testing:
	1 medicare-prod-predeploy.cgifederal.com
	2 qa.medicare.gov
	3 staging.medicare.gov
	4 www.medicare.gov'
	
	environment = gets.strip!
	case environment
		when "1"
			env = "medicare-prod-predeploy.cgifederal.com/physicianservices/Provider.svc/GetList/GETPRFLOCINFO"
			valid = true
		when "2"
			env = "qa.medicare.gov/physicianservices/Provider.svc/GetList/GETPRFLOCINFO"
			valid = true
		when "3"
			env = "staging.medicare.gov/physicianservices/Provider.svc/GetList/GETPRFLOCINFO"
			valid = true
		when "4"
			env = "www.medicare.gov/physicianservices/Provider.svc/GetList/GETPRFLOCINFO"
			valid = true
		when "5"
			env ="medicare-iterationb1.cgifederal.com/physicianservices/Provider.svc/GetList/GETPRFGENINFO"
			valid = true
		else
		   puts "Invalid input\nPlease try again\n\n"
	end
end #end until

puts "What size sample would you like to test? (input a number 0-100)"
sample = gets.chomp!
sample = sample.to_f/100

puts "Testing #{sample*$adds.count} adds and #{sample*$deletes.count} deletes."

puts "Comparing first #{sample} added providers to web service."
outputFile.write("Physician DB Validation\n#{env}\n

Result  Change  ID		Differences\n")

$adds[0...sample*$adds.count].each do |item|
	provider_id = item[0]
	last_name = item[1]
	first_name = item[2]
	gender = item[3]
	full_name = "#{first_name} #{last_name}"
	db_record = [full_name]
	begin
		response = Curl::Easy.perform("http://#{env}/prvdr_id%7c#{provider_id}") do |curl| 
			curl.headers["cookie"] = "ASPSessionKey="
		end
	rescue
		tries ||= 5
		puts "There was an issue with the connection, waiting 30 seconds and trying again"
		sleep 30
		#tries = tries - 1
		if tries > 0
			retry
		else
			abort("webservice connection is unstable. aborting test. Please try again later.")
		end
	end
	doc = Nokogiri::HTML(response.body_str)
	json = JSON.parse(doc.css("p").text)
	json["GetListResult"].each do |item|
		first_name = item["AdditionalInfo"][1]["Value"]
		last_name = item["AdditionalInfo"][2]["Value"]
		full_name = "#{first_name} #{last_name}"
		web_record = [full_name]
	end
	
	missing = web_record - db_record
	if missing.empty?
		puts "PASSED + Added + #{provider_id} \n"
		outputFile.write("PASSED + Added + #{provider_id} \n")
		passed << "+ Added + #{provider_id}"
	else
		print "FAILED + Added + #{provider_id} "
		missing.each do |item|
			print "#{item} "
		end#end missing
		failed << "+ Added + #{provider_id} #{miss}"
		outputFile.write("FAILED + Added + #{provider_id} ")
		missing.each do |item|
			outputFile.write("#{item} ")
		end
		outputFile.write("\n")
		print "\n"
	end#end if
end#end $records

puts "Comparing first #{sample*$deletes.count} deleted providers to web service."

$deletes[0...sample*$deletes.count].each do |item|
	provider_id = item[0]
	begin
		response = Curl::Easy.perform("http://#{env}/prvdr_id%7c#{provider_id}") do |curl| 
			curl.headers["cookie"] = "ASPSessionKey="
		end
	rescue
		tries ||= 5
		puts "There was an issue with the connection, waiting 30 seconds and trying again"
		sleep 30
		#tries = tries - 1
		if tries > 0
			retry
		else
			abort("webservice connection is unstable. aborting test. Please try again later.")
		end
	end
	doc = Nokogiri::HTML(response.body_str)
	json = JSON.parse(doc.css("p").text)
	if json["GetListResult"] == []
		puts "PASSED -Deleted- #{provider_id}"
		outputFile.write("PASSED -Deleted- #{provider_id}\n")
		passed << "+ Added + #{provider_id}"
	else
		puts "FAILED -Deleted- #{provider_id}"
		outputFile.write("FAILED -Deleted- #{provider_id}\n")
		failed << "-Deleted- #{provider_id}"
	end
end

outputFile.write("Passed: #{passed.count}\nFailed: #{failed.count}")
puts "#{failed.count} have failed.\n#{passed.count} have passed."
outputFile.close