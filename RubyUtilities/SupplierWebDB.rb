#  Program to test the Supplier database for changes via webservice calls
#    This program uses the output report from SupplierDataDelta.rb
#
#  Created 12/31/2013 by Adam Stetser
# Update 05/31/2015 - Todd Jones - Changed the way the script retries when the webservice is unstable.


require 'curb'
require 'nokogiri'

@local_filename

def filename(d)
   local_filename1 = "../output/SupplierWebDB" #need to have file name change by day
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


puts "Supplier DB Webservice test"

delta_file = Dir.glob("../output/Supplier_Ruby_DeltaAuto*") 
file_location = delta_file[-1].gsub("/", "\\")

#Checks the DeltaAuto file for the "no change" tag to abort the script.
text=File.open(file_location).read
if text == "no change" 
	puts "\n!!Warning!!\n\nThe were no detected changes within the delta file.\nPlease ensure that the correct current and prior input files were used.\nConfirm with the technical team that the files should have the same content."
	File.open(@local_filename, 'w') { |f| 
		f.write("There were no changes detected within #{file_location}\n")
			f.write("The likely cause is the current and prior pecos files are identical.\nPlease confirm with the technical team that this is expected.")}
	abort "Ending script"
end
puts "Using #{file_location} as the input delta file\n\n"


puts "Enter the number for the environment you are testing"
puts "1 medicare-prod-predeploy.cgifederal.com"
puts "2 QA.medicare.gov"
puts "3 Staging.medicare.gov"
puts "4 www.medicare.gov"
valid = false
until valid
environment = gets
environment.strip!

case environment 
when "1"
	env = "medicare-prod-predeploy.cgifederal.com/supplierservices/Provider.svc/GetProvidersByIDsXML"
	valid = true
when "2"
   env = "qa.medicare.gov/supplierservices/Provider.svc/GetProvidersByIDsXML"
   valid = true
when "3"
   env = "staging.medicare.gov/supplierservices/Provider.svc/GetProvidersByIDsXML"
   valid = true
when "4"
   env = "www.medicare.gov/supplierservices/Provider.svc/GetProvidersByIDsXML"
   valid = true
else
   puts "Invalid input"
end
end

outputFile = File.open(@local_filename, 'a') 
outputFile.write(
"Supplier DB Validation"+"\n"+
t.strftime("%m/%d/%Y %H:%M")+"\n"+
env+"\n\n"+
"Result  Change  ID        Differences"+"\n")

puts env

#read SupplierDataDelta file by record
File.foreach(file_location) {|deltaRecord| 


##parse record
   action = deltaRecord[0..9].strip
   deltaID = deltaRecord[11..20].strip
   deltaName = deltaRecord[30..99].strip
   deltaDba_name = deltaRecord[100..169].strip
   deltaAdr1 = deltaRecord[170..224].strip
   deltaAdr2 = deltaRecord[225..279].strip
   deltaCity = deltaRecord[280..309].strip
   deltaState = deltaRecord[310..311].strip
   deltaZip = deltaRecord[312..316].strip
   deltaPhone = deltaRecord[327..336].strip.insert(6,'-').insert(3,'-')
   
   deltaRecord = [deltaID, deltaName, deltaDba_name, deltaAdr1, deltaAdr2, deltaCity, deltaState, deltaZip, deltaPhone]


#Make the webservice call and if it fails, wait 15 secs and try one more time
   begin  
      response = Curl::Easy.perform("http://#{env}/#{deltaID}") do |curl| 
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

   html_doc = Nokogiri::HTML(response.body_str)

    
   dbID = html_doc.css('id').text
   dbName = html_doc.css('name').text

   html_doc.css('supl keyvalueofstringstring key').each do |node1|
      if node1.text=='dba_name'
            dbDba_name = node1.next.text #assuming that the value is the next node, returns the dba_name
      end
   end

   dbDba_name
   dbAdr1 = html_doc.css('adr1').text
   dbAdr2 = html_doc.css('adr2').text
   dbCity = html_doc.css('city').text
   dbState = html_doc.css('state').text
   dbZip = html_doc.css('zip').text
   dbPhone = html_doc.css('phone').text.gsub(/[()-]/,"").gsub(/\s/,"")
   if !dbPhone.empty?
      dbPhone = dbPhone.insert(6,'-').insert(3,'-')
   end
   
   dbRecord = [dbID, dbName, dbDba_name, dbAdr1, dbAdr2, dbCity, dbState, dbZip, dbPhone]
   
   
# Generate Testing Results Report
   
   case action 
   when "+ Added +"
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
      dbRecord.reject! {|c| c.empty?}  #remove blank entries
      deleted_count = deleted_count +1
      if dbRecord.empty?
         print "PASSED -Deleted- "+deltaID +"\n"
         outputFile.write("PASSED -Deleted- "+deltaID +"\n")
         passed_count = passed_count + 1
      else
         print "FAILED -Deleted- "+" "
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
   
# Cleanup and End SupplierDataDelta read loop with brace below
dbDba_name = ""
}

total_count = added_count + deleted_count + changed_count
t = Time.now
outputFile.write(
"\nSupplier DB Validation Complete"+"\n"+t.strftime("%m/%d/%Y %H:%M")+"\n"+
"Number Added = "+added_count.to_s+"\n"+
"Number Deleted = "+deleted_count.to_s+"\n"+
"Number Changed = "+changed_count.to_s+"\n"+
"Total = "+total_count.to_s+"\n\n"+
"PASSSED = "+passed_count.to_s+"\n"+ 
"FAILED = "+failed_count.to_s+"\n\n")

outputFile.close
puts "Done\a"