#  Program to test the NHC database for changes via webservice calls
#    This program uses the output report from NHCDelta3.rb
#
#  Created 1/7/2014 by Adam Stetser


require 'curb'
require 'nokogiri'

@local_filename

def filename(d)
   local_filename1 = "../output/NHCWebDB" #need to have file name change by day
   filedate = d.strftime("%m%d%Y")
   local_filename2 = '.txt'
   @local_filename = local_filename1+filedate+local_filename2
end

t=Time.now
filename(t)
env=String.new
dbDba_name = String.new
added_count = 0
deleted_count = 0
changed_count = 0
total_count = 0
passed_count = 0
failed_count = 0

puts "Monitoring in process"
puts "NHC DB Web test"
delta_file = Dir.glob("../output/NHC_Ruby_DeltaAuto*") 
file_location = delta_file[-1].gsub("/", "\\")
puts "Using #{file_location} as the input delta file\n\n"

env = "nil"
until env != "nil"

puts "Enter the number for the environment you are testing"
puts "1 medicare-prod-predeploy.cgifederal.com"
puts "2 QA.medicare.gov"
puts "3 Staging.medicare.gov"
puts "4 www.medicare.gov"
puts "5 medicare-iterationb1-test.cgifederal.com"

environment = gets
environment.strip!

case environment 

when "1"
	env = "medicare-prod-predeploy.cgifederal.com/nursinghomeservices/provider.svc/GetProvidersByIDsXML"
when "2"
	env = "qa.medicare.gov/nursinghomeservices/provider.svc/GetProvidersByIDsXML"
when "3"
	env = "staging.medicare.gov/nursinghomeservices/provider.svc/GetProvidersByIDsXML"
when "4"
	env = "www.medicare.gov/nursinghomeservices/provider.svc/GetProvidersByIDsXML"
when "5"
	env = "medicare-iterationb1-test.cgifederal.com/nursinghomeservices/provider.svc/GetProvidersByIDsXML"
else
	puts "Invalid input\n"	
	env = "nil"
end
end #end loop for prompting until valid input

outputFile = File.open(@local_filename, 'a') 
outputFile.write(
"NHC DB Validation"+"\n"+
t.strftime("%m/%d/%Y %H:%M")+"\n"+
env+"\n\n"+
"Result  Change  ID     Differences"+"\n")

puts env

#read NHC DataDelta file by record
File.foreach(file_location) {|deltaRecord| 

##parse record
   action = deltaRecord[0..9].strip
   deltaID = deltaRecord[11..16].strip
   parsedDeltaRecord = deltaRecord.split(/\t/)
   deltaName = parsedDeltaRecord[1].strip
   deltaAdr1 = parsedDeltaRecord[2].strip
   deltaCity = parsedDeltaRecord[3].strip
   deltaState = parsedDeltaRecord[4].strip
   deltaZip = parsedDeltaRecord[5].strip
   deltaPhone = parsedDeltaRecord[6].strip.gsub(/[()-]/,"").gsub(/\s/,"")
   if !deltaPhone.empty?
      deltaPhone = deltaPhone.insert(6,'-').insert(3,'-')
   end
   deltaOvrl = parsedDeltaRecord[7]
   deltaInsp = parsedDeltaRecord[8]
   deltaStff = parsedDeltaRecord[9]
   deltaQlty = parsedDeltaRecord[10]
   deltaRecord = [deltaID, deltaName, deltaAdr1, deltaCity, deltaState, deltaZip, deltaPhone, deltaOvrl, deltaInsp, deltaStff, deltaQlty]#


#Make the webservice call and if it fails, wait 15 secs and try one more time
   begin  
      response = Curl::Easy.perform("http://#{env}/#{deltaID}") do |curl| 
          curl.headers["cookie"] = "ASPSessionKey="
      end
   rescue
     
        puts "There was an issue with the connection, waiting 10 seconds and trying again"
        sleep 10
        begin   
           response = Curl::Easy.perform("http://#{env}/#{deltaID}") do |curl| 
   	#   response = Curl::Easy.perform("http://#{env}/0279613436") do |curl| 
   	      curl.headers["cookie"] = "ASPSessionKey="
	  end
        rescue
           puts "webservice connection is unstable, aborting test. Please try again later"
           Process.exit
        end

   end
	xml_doc = Nokogiri::XML(response.body_str)
	html_doc = Nokogiri::HTML(response.body_str)
#   puts html_doc.text
	if xml_doc.at('ProviderFinderDO') != NIL
		dbID = html_doc.css('id').text
		dbName = html_doc.css('name').text
		dbAdr1 = html_doc.css('adr1').text
		dbCity = html_doc.css('city').text
		dbState = html_doc.css('state').text
		dbZip = html_doc.css('zip').text
		dbPhone = html_doc.css('phone').text.gsub(/[()-]/,"").gsub(/\s/,"")
		if !dbPhone.empty?
			dbPhone = dbPhone.insert(6,'-').insert(3,'-')
		end
		dbOvrl = html_doc.css('value')[0].text.split("|")[0]
		dbInsp = html_doc.css('value')[1].text.split("|")[0]
		dbStf = html_doc.css('value')[2].text.split("|")[0]
		dbQlty = html_doc.css('value')[3].text.split("|")[0]
		dbRecord = [dbID, dbName, dbAdr1, dbCity, dbState, dbZip, dbPhone, dbOvrl, dbInsp, dbStf, dbQlty]
	else
		dbRecord = []
	end
# Generate Testing Results Report
   
   case action 
   when "+ Added +"
      added_count = added_count +1
      missing = deltaRecord - dbRecord
      missing.compact!
      if missing.empty?
         print "PASSED + Added + #{deltaID} \n"
         outputFile.write("PASSED +Added+ #{deltaID} \n")
         passed_count = passed_count + 1
      else
         print "FAILED +Added+ #{deltaID} "
         outputFile.write("FAILED +Added+ #{deltaID} ")
         missing.each do |item|
            print item+" "
            outputFile.write(item + " ")
         end
         print "\n"
         outputFile.write("\n")
         failed_count = failed_count+1
      end
   when "-Deleted-"
      dbRecord.reject! {|c| c.empty?}  #remove blank entries
      deleted_count = deleted_count +1
      if dbRecord.empty?
         print "PASSED -Deleted- #{deltaID} \n"
         outputFile.write("PASSED -Deleted- "+deltaID +"\n")
         passed_count = passed_count + 1
      else
         print "FAILED -Deleted- "+" "
         outputFile.write("FAILED -Deleted- "+" ")
         dbRecord.each do |item|
            print item+" "
            outputFile.write("#{item} ")
         end
         print "\n"
         outputFile.write("\n")
         failed_count = failed_count+1
      end
   when "New Data"
      missing = deltaRecord - dbRecord
      changed_count = changed_count + 1
      missing.compact!
      if missing.empty?
         print "PASSED"+" New Data "+deltaID +"\n"
         outputFile.write("PASSED New Data " +deltaID+"\n")
         passed_count = passed_count + 1
      else
         print "FAILED New Data "+deltaID +" "
         outputFile.write("FAILED New Data "+deltaID +" ")
         missing.each do |item|
            print item+" "
            outputFile.write(item +" ")
         end
         print "\n"
         outputFile.write("\n")
         failed_count = failed_count+1
      end
   else
      puts "Invalid input"
   end


   
# Cleanup and End NHCDataDelta read loop with brace below
dbDba_name = ""
}

total_count = added_count + deleted_count + changed_count
t = Time.now
outputFile.write(
"\nNHC DB Validation Complete"+"\n"+t.strftime("%m/%d/%Y %H:%M")+"\n"+
"Number Added = "+added_count.to_s+"\n"+
"Number Deleted = "+deleted_count.to_s+"\n"+
"Number Changed = "+changed_count.to_s+"\n"+
"Total = "+total_count.to_s+"\n\n"+
"PASSSED = "+passed_count.to_s+"\n"+ 
"FAILED = "+failed_count.to_s+"\n\n") 

outputFile.close










