#Todd Jones - SupplierModels.rb script
#Purpose - to compare a delta file against the supplier providers products web service
require 'curb'
require 'nokogiri'

fail=[]
pass=[]
model_hash = Hash.new
t = Time.now
valid = false
until valid
	puts "Enter the number for the environment you are testing:
	1 medicare-prod-predeploy.cgifederal.com
	2 qa.medicare.gov
	3 staging.medicare.gov
	4 www.medicare.gov"
	environment = gets.strip!
	case environment
		when "1"
			env = "medicare-prod-predeploy.cgifederal.com/supplierservices/Provider.svc/GetProvidersProducts"
			valid = true
		when "2"
			env = "qa.medicare.gov/supplierservices/Provider.svc/GetProvidersProducts"
			valid = true
		when "3"
			env = "staging.medicare.gov/supplierservices/Provider.svc/GetProvidersProducts"
			valid = true
		when "4"
			env = "www.medicare.gov/supplierservices/Provider.svc/GetProvidersProducts"
			valid = true
		else
		   puts "Invalid input\nPlease try again\n\n"
	end
end #end until
outputFile = File.open("../output/SupplierModels_"+"#{t.strftime("%Y%m%d")}.txt", "a")
#INPUT file section
delta_file = Dir.glob("../output/brand_extract_delta*") 
file_location = delta_file[-1].gsub("/", "\\")
puts "Parsing #{file_location} as input file. 
This may take a minute...\n\n"
File.foreach(file_location) do |line|
	parsed_line = line.split("\t")
	action = parsed_line[0]
	deltaID = parsed_line[1]
	deltaCBSA = parsed_line[2]
	deltaCTGY = parsed_line[3]
	deltaMFTR = parsed_line[4]
	deltaModel = parsed_line[5].strip
	model_hash["#{deltaID}|""#{deltaCBSA}|""#{deltaCTGY}|""#{deltaMFTR}|""#{action}"] ||= []
	model_hash["#{deltaID}|""#{deltaCBSA}|""#{deltaCTGY}|""#{deltaMFTR}|""#{action}"] << "#{deltaModel}" # Loads all of the models into a hash
end

model_hash.each do |deltaID, deltaModel|
	parsedID = deltaID.split('|')
	deltaID = parsedID[0]
	deltaCBSA = parsedID[1]
	deltaCTGY = parsedID[2]
	deltaMFTR = parsedID[3]
	action = parsedID[4]
	begin
	response = Curl::Easy.perform("http://#{env}/#{deltaID}/#{deltaCBSA}/#{deltaCTGY}") do |curl| 
		curl.headers["cookie"] = "ASPSessionKey="
	end
	rescue
		tries ||= 5
		puts "There was an issue with the connection, waiting 30 seconds and trying again."
		sleep 30
		tries -= 1
		if tries > 0
			retry
		else
			abort("webservice connection is unstable - aborting test.\nPlease try again later.")
		end
	end
	doc = Nokogiri::HTML(response.body_str)
	db_models = []
	doc.css("mftrname").each do |item|
		name = item.text
		models = item.next
		db_models.push models.text.split('|')
	end
	
	db_models.flatten!
	deltaModel.each do |model|
		if action == "+ ADDED +"
			if db_models.grep("#{model}").any?
				puts "PASS + ADDED + #{deltaID} #{model}"
				pass << "#{deltaID} #{model}"
			else
				puts "FAIL + ADDED + #{deltaID} #{model}"
				fail << "+ ADDED +\t#{deltaID}\t#{deltaCBSA}\t#{deltaCTGY}\t#{deltaMFTR}\t#{model}"
			end #end if
		elsif action == "-DELETED-"
			if doc.css("mftrname").grep("#{deltaMFTR}").any? == FALSE
				puts "PASS -DELETED- #{deltaID} #{model}"
				pass << "#{deltaID} #{model}"
			elsif db_models.grep("#{model}").any?
				puts "FAIL -DELETED- #{deltaID} #{model}"
				fail << "-DELETED-\t#{deltaID}\t#{deltaCBSA}\t#{deltaCTGY}\t#{deltaMFTR}\t#{model}"
			else
				puts "PASS -DELETED- #{deltaID} #{model}"
				pass << "#{deltaID} #{model}"
			end #end if
		end #end if
	end #end models loop
end #end hash loop

puts "#{pass.count} have passed\n#{fail.count} have failed."
#output file section
outputFile.write("Supplier Models Validation Complete
#{t.strftime("%m/%d/%Y %H:%M")}
#{env}
Total items changed: #{pass.count + fail.count}
#{pass.count} have passed
#{fail.count} have failed\n\n")
outputFile.write("PASSED Items
--------------------\n")

pass.each do |item|
	outputFile.write("PASSED #{item}\n")
end

outputFile.write("\nFAILED Items
--------------------\n")
fail.each do |item|
	outputFile.write("FAILED #{item}\n")
end
outputFile.close
puts "Done\a"