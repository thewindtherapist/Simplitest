	# Script to compare NHC Delta Auto file against the published socrata files
# This program uses the output from NHCDelta.rb
# Todd Jones
# March 17, 2014


require 'curb'
require 'nokogiri'
require 'json'

@local_filename

def filename(d)
   local_filename1 = 'c:\ruby\nhc\output\NHCSocrataDB' #need to have file name change by day
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
puts "NHC DB Socrata test"

# Gets the latest generated delta file for input
delta_file = Dir.glob("C:/Ruby/NHC/output/NHC_Ruby_DeltaAuto*") 
file_location = delta_file[-1].gsub("/", "\\")
puts "Using #{file_location} as the delta file..."
# Gets the last part of the url - NOTE - This does not validate if it is a valid ID
puts "Please input the Provider-Info dataset ID: "
#dataID = "hq9i-23gr"
dataID = gets.strip
puts "Using #{dataID} as dataset ID"


outputFile = File.open(@local_filename, 'a') 
outputFile.write(
"NHC Socrata Validation"+"\n"+
t.strftime("%m/%d/%Y %H:%M")+"\n"+
env+"\n\n"+
"Result  Change  ID        Differences"+"\n")


File.foreach(file_location) {|deltaRecord| 

##parse record
   action = deltaRecord[0..9].strip
   deltaID = deltaRecord[11..16].strip
   
   parsedDeltaRecord = deltaRecord.split(/\t/)
   
   deltaName = parsedDeltaRecord[1].strip
#   deltaDba_name = parsedDeltaRecord[].strip
   deltaAdr1 = parsedDeltaRecord[2].strip
#   deltaAdr2 = parsedDeltaRecord[].strip
   deltaCity = parsedDeltaRecord[3].strip
   deltaState = parsedDeltaRecord[4].strip
   deltaZip = parsedDeltaRecord[5].strip
   
   deltaPhone = parsedDeltaRecord[6].strip.gsub(/[()-]/,"").gsub(/\s/,"")
   if !deltaPhone.empty?
      deltaPhone = deltaPhone.insert(6,'-').insert(3,'-')
   end
   
#   deltaRecord = [deltaID, deltaName, deltaDba_name, deltaAdr1, deltaAdr2, deltaCity, deltaState, deltaZip, deltaPhone]
   deltaRecord = [deltaID, deltaName, deltaAdr1, deltaCity, deltaState, deltaZip, deltaPhone]


#Make the webservice call and if it fails, wait 15 secs and try one more time
   begin  
      response = Curl::Easy.perform("http://data.medicare.gov/resource/#{dataID}.json?$query=select+federal_provider_number,provider_phone_number.phone_number,provider_name,provider_address,provider_city,provider_state,provider_zip_code+where+federal_provider_number='#{deltaID}'") do |curl| 
          curl.headers["cookie"] = "ASPSessionKey="
      end
   rescue
     
        puts "There was an issue with the connection, waiting 5 seconds and trying again"
        sleep 5
        begin   
			response = Curl::Easy.perform("http://data.medicare.gov/resource/#{dataID}.json?$query=select+federal_provider_number,provider_phone_number.phone_number,provider_name,provider_address,provider_city,provider_state,provider_zip_code+where+federal_provider_number='#{deltaID}'") do |curl| 
   	#   response = Curl::Easy.perform("http://#{env}/0279613436") do |curl| 
			curl.headers["cookie"] = "ASPSessionKey="
	  end
        rescue
           puts "webservice connection is unstable, aborting test. Please try again later"
           Process.exit
        end

   end

 
   json = Nokogiri::HTML(response.body_str)
   parsed_json = JSON.parse(json)

parsed_json.each do |doc|
	dbID = doc["federal_provider_number"]
	dbAdr1 = doc["provider_address"]
	dbCity = doc["provider_city"]
	dbState = doc["provider_state"]
	dbZip = doc["provider_zip_code"]
	dbName =doc["provider_name"]
	dbPhone = doc["sub_col_provider_phone_number_phone_number"].gsub(/[()-]/,"").gsub(/\s/,"")
	if !dbPhone.empty?
		dbPhone = dbPhone.insert(6, '-').insert(3, '-')
	end #endif
	@dbRecord = [ dbID, dbName, dbAdr1, dbCity, dbState, dbZip, dbPhone ]
end #end loop

   
# Generate Testing Results Report
   
  case action 
   when "+ Added +"
   dbRecord = @dbRecord
      added_count = added_count +1
      missing = deltaRecord - dbRecord

      missing.compact!
      if missing.empty?
         print "PASSED + Added + "+deltaID +"\n"
         outputFile.write("PASSED +Added+ "+deltaID +"\n") 
         passed_count = passed_count + 1
      else
         print "FAILED + Added + #{deltaID} "
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
	#dbRecord = @dbRecord
	#dbRecord.reject! {|c| c.empty?}  #remove blank entries
    deleted_count = deleted_count +1

      if dbRecord == nil
         puts "PASSED -Deleted- #{deltaID}"
         outputFile.write("PASSED -Deleted- #{deltaID} \n")
         passed_count = passed_count + 1
      else
         puts "FAILED -Deleted- #{deltaID}"
         outputFile.write("FAILED -Deleted- ")
         dbRecord.each do |item|
            print item+" "
            outputFile.write(item + " ")
		end
		print "\n"
         outputFile.write("\n")
         failed_count = failed_count+1
      end
      
   when "New Data"
      missing = deltaRecord - @dbRecord
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
"\nNHC Socrata Validation Complete"+"\n"+t.strftime("%m/%d/%Y %H:%M")+"\n"+
"Number Added = "+added_count.to_s+"\n"+
"Number Deleted = "+deleted_count.to_s+"\n"+
"Number Changed = "+changed_count.to_s+"\n"+
"Total = "+total_count.to_s+"\n\n"+
"PASSSED = "+passed_count.to_s+"\n"+ 
"FAILED = "+failed_count.to_s+"\n\n")

outputFile.close