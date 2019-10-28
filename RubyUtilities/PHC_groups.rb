require 'nokogiri'
require 'curb'
require 'json'

group_add_xml = '../input/Group_Add.xml'
group_del_xml = '../input/group_Del.xml'
$deletes = Array.new
$adds = Array.new
outputFile = File.open("../output/Group_results_#{Time.now.strftime("%Y%m%d")}.txt", 'a')
address_file = "Address_File.txt"
sample = 1
db_record = Array.new
web_record = Array.new
miss = Array.new
failed = Array.new
passed = Array.new

def parse(input_file, output_array)
	puts "Parsing #{input_file} data. Please wait..."
	doc = Nokogiri::XML(File.read(input_file))
	doc.search('Group').map do |group|
		output_array << [group['org_pac_id'], group.at('org_legal_name').text.upcase, group.at('GPRO_status').text, group.at('ERX_status').text, group.at('par_status').text, group.at('Location')['adrs_id']]
	end
end

def parse_del(input_file, output_array)
	puts "Parsing #{input_file} data. Please wait..."
	doc = Nokogiri::XML(File.read(input_file))
	doc.xpath("//Group").each do |group|
		output_array << [group["org_pac_id"]]
	end
end

def missing(ar_1, ar_2)
	(ar_1 + ar_2) - (ar_1 & ar_2) 
end

parse(group_add_xml, $adds)
parse_del(group_del_xml, $deletes)

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
			env = "medicare-prod-predeploy.cgifederal.com/physicianservices/Provider.svc/GetList/GETGRPGENINFO"
			valid = true
		when "2"
			env = "qa.medicare.gov/physicianservices/Provider.svc/GetList/GETGRPGENINFO"
			valid = true
		when "3"
			env = "staging.medicare.gov/physicianservices/Provider.svc/GetList/GETGRPGENINFO"
			valid = true
		when "4"
			env = "www.medicare.gov/physicianservices/Provider.svc/GetList/GETGRPGENINFO"
			valid = true
		else
		   puts "Invalid input\nPlease try again\n\n"
	end
end #end until

puts "What size sample would you like to test? (input a number 0-100)"
sample = gets.chomp!
sample = sample.to_f/100

puts "Testing #{sample*$adds.count} adds and #{sample*$deletes.count} deletes."

outputFile.write("Testing Physician group adds and deletes
#{env} 
#{Time.now}
Number of new groups: #{$adds.count}
Number of old groups: #{$deletes.count}
Total changes: #{$adds.count+$deletes.count}
Results
------------\n")

$adds[0...sample*$adds.count].each do |item|
	group_id = item[0]
	group_name = item[1]
	gpro_status = item[2]
	erx_status = item[3]
	par_status = item[4]
	loc_id = item[5]
	db_record = [group_id, group_name, gpro_status, erx_status, par_status]
	
	begin
		response = Curl::Easy.perform("http://#{env}/sltdid%7c#{group_id}") do |curl| 
			curl.headers["cookie"] = "ASPSessionKey="
		end
	rescue
		tries ||= 5
		puts "There was an issue with the connection, waiting 30 seconds and trying again"
		sleep 30
		if tries > 0
			retry
		else
			abort("Webservice connection is unstable. aborting test. Please try again later.\a\a")
		end
	end
	doc = Nokogiri::HTML(response.body_str)
	json = JSON.parse(doc.css("p").text)
	name = json["GetListResult"][0]["Name"].upcase
	id = json["GetListResult"][0]["ID"]
	if json["GetListResult"][0]["AdditionalInfo"][0]["Value"] != ""
		gpro = "Y"
	else
		gpro = "N"
	end
	if json["GetListResult"][0]["AdditionalInfo"][1]["Value"] != ""
		erx = "Y"
	else
		erx = "N"
	end
	if json["GetListResult"][0]["AdditionalInfo"][5]["Value"] == "True"
		par_stat = "Y"
	else
		par_stat = "N"
	end
	
	web_record = [id, name, gpro, erx, par_stat]

	missing = missing(web_record, db_record)

	if missing.empty?
		puts "PASSED + Added + #{group_id} \n"
		outputFile.write("PASSED + Added + #{group_id}\n")
		passed << "+ Added + #{group_id}"
	else
		print "FAILED + Added + #{group_id} "
		missing.each do |item|
			print item
		end
		outputFile.write("FAILED + Added + #{group_id} ")
			missing.each do |item|
				outputFile.write("#{item} ")
			end
			outputFile.write("\n")
			failed << "+ Added + #{group_id}"
			print "\n"
	end
end

$deletes[0...sample*$deletes.count].each do |item|
	group_id = item[0]
	begin
		response = Curl::Easy.perform("http://#{env}/sltdid%7c#{group_id}") do |curl| 
			curl.headers["cookie"] = "ASPSessionKey="
		end
	rescue
		tries ||= 5
		puts "There was an issue with the connection, waiting 30 seconds and trying again"
		sleep 30
		if tries > 0
			retry
		else
			abort("webservice connection is unstable. aborting test. Please try again later.\a\a")
		end
	end
	doc = Nokogiri::HTML(response.body_str)
	json = JSON.parse(doc.css("p").text)
	if json["GetListResult"] == []
		puts "PASSED -Deleted- #{group_id}"
		outputFile.write("PASSED -Deleted- #{group_id}\n")
		passed << "-Deleted- #{group_id}"
	else
		puts "FAILED -Deleted- #{group_id}"
		outputFile.write("FAILED -Deleted- #{group_id}\n")
		failed << "-Deleted- #{group_id}"
	end
end
puts "#{passed.count} have passed.\n#{failed.count} have failed."
outputFile.write("\n\nPassed:#{passed.count}\nFailed:#{failed.count}\n\n")
outputFile.write("Time Completed #{Time.now}")
outputFile.close