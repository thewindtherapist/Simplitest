# Downloadable.rb
#
#    Program to download the "Downloadable Databases" from Medicare.gov
#    and report on the file date and size of each file within the zip file
#    the program can download from production, QA, Staging, or IHOP environments
#
# Created: 5/3/2011 Adam Stetser

require 'rubygems'
require 'net/http'
#require 'AccessDb'
require 'zip/zipfilesystem'
#require 'activesupport'


# Download file and save to output folder
def download(url, filename, outputFolder)
   loadStatus = true
   begin
      Net::HTTP.start(url) { |http|
         t= Time.now
         filedate = t.strftime("%m%d%Y")
		if url == "downloads.cms.gov"
			resp = http.get("/medicare/#{filename}")
		else
			resp = http.get("/download/#{filename}")
		end

        open("#{outputFolder}#{filedate}#{filename}", "wb") { |file|
          file.write(resp.body)
        }
      }

   puts "download of #{filename} complete"
   rescue Exception=>e
      loadStatus = false
   end
   return loadStatus
end


# Create log file
def logFilename(d)
   workingFile = 'downloadLog'
   filedate = d.strftime("%m%d%Y")
   local_filename2 = '.txt'
   @log_filename = '../logs/'+workingFile+filedate+local_filename2
end
quit = 'n'
while quit == 'n'
# Main program ###############################################
saveLocation = "c:/ruby/download/"
urlInput = String.new
input = String.new
inputa = Array.new()
fileList = Array.new()
t=Time.now
logFilename(t)



puts "Enter number for environment to download"
puts "1. www.medicare.gov"
puts "2. qa.medicare.gov"
puts "3. staging.medicare.gov"
puts "4. ihop.cgifederal.com"
puts "5. MANUAL input"
urlInput = gets.chomp

case urlInput
     when "1"
        url = "downloads.cms.gov"
     when "2"
        url = "qa.medicare.gov"
     when "3"
        url = "staging.medicare.gov"
     when "4"
        url = "ihop.cgifederal.com"
	 when "5"
		puts "Enter your manual URL:"
		url = gets.chomp

end

puts ""
puts "Enter number for downloads. Multiple items can be downloaded by entering a space between each value"
puts "1. Contacts"
puts "2. Coverage"
puts "3. Dialysis"
puts "4. Home Health"
puts "5. Hospital"
puts "6. Med"
puts "7. MCG Compare"
puts "8. NHC"
puts "9. Plan Info County 1"
puts "10. Plan Info County 2"
puts "11. Plan Ratings"
puts "12. Supplier"
input = gets.chomp


inputa = input.split(" ")
puts inputa

inputa.each do |m|
# Updated: 3/19/2013 Roehl Pangilinan - updated following Plan Finder file names: Med2000, MGCompare, county 1, county 2, plan ratings
# Updated: 10/28/2013 Roehl Pangilinan - updated following Plan Finder file names: Med2000, MGCompare, county 1, county 2, plan ratings
  case m
     when "1"
      fileList.push %w{HelpfulContacts.zip HelpfulContacts_Revised_flatfiles.zip HelpfulContacts_flatfiles.zip}
     when "2"
      fileList.push %w{Coverage.zip}
     when "3"
      fileList.push %w{DFCompare.zip DFCompare_Revised_flatfiles.zip DFCompare_flatfiles.zip}
     when "4"
      fileList.push %w{HHCompare.zip HHCompare_Revised_flatfiles.zip HHCompare_flatfiles.zip}
     when "5"
       fileList.push %w{Hospital.zip Hospital_Revised_flatfiles.zip Hospital_flatfiles.zip}
     when "6"
       fileList.push %w{2014Med2000.zip 2014Med2000_flatfiles.zip}
     when "7"
       fileList.push %w{2014MGCompare.zip 2014MGCompare_flatfiles.zip}
     when "8"
       fileList.push %w{NHCAboutNH.zip NHCAboutNH_flatfiles.zip NHCInspRes.zip NHCInspRes_flatfiles.zip NHCRatings.zip NHCRatings_flatfiles.zip NHCResidents.zip NHCResidents_flatfiles.zip NHCStaff.zip NHCStaff_flatfiles.zip NHCompare_Revised_flatfiles.zip}
     when "9"
       fileList.push %w{2014Med2000_PlanInfoCounty1.zip 2014Med2000_PlanInfoCounty1_flatfiles.zip}
     when "10"
       fileList.push %w{2014Med2000_PlanInfoCounty2.zip 2014Med2000_PlanInfoCounty2_flatfiles.zip}
     when "11"
       fileList.push %w{2014PlanRatings.zip 2014PlanRatings_flatfiles.zip}
     when "12"
       fileList.push %w{Supplier.zip Supplier_Revised_flatfiles.zip Supplier_flatfiles.zip}
    end   
end

fileList.flatten!

File.open(@log_filename, 'a') {|f| f.write("Downloadable DB Test Process started " + t.strftime("%m/%d/%Y %H:%M:%S")+"\n")}

fileList.each do |item|
   loadStatus = true

   filedate = t.strftime("%m%d%Y")
   loadStatus = download(url.to_s , item.to_s, saveLocation.to_s)
   
   if loadStatus == true
      zip = Zip::ZipFile.open(saveLocation.to_s+filedate+item.to_s)
      zipSize = File.size(saveLocation.to_s+filedate+item.to_s)
      zipContents = zip.to_a
      File.open(@log_filename, 'a') {|f| f.write(t.strftime("%m/%d/%Y %H:%M:%S")+" - "+zip.name.to_s+" successfully downloaded from "+url.to_s + " Zip file size= "+zipSize.to_s+"\n") }
      zipContents.each do |zipItem|
          t= Time.now
          File.open(@log_filename, 'a') {|f| f.write(t.strftime("%m/%d/%Y %H:%M:%S")+" - "+zipItem.name.to_s+" size= "+zipItem.size.to_s+" date= "+zipItem.time.strftime("%m/%d/%Y  %H:%M:%S")+"\n") }
          puts t.strftime("%m/%d/%Y %H:%M:%S")+" - "+zipItem.name.to_s+" size= "+zipItem.size.to_s+" date= "+zipItem.time.strftime("%m/%d/%Y  %H:%M:%S")
      end
   else
      puts item.to_s+" FAILED TO DOWNLOAD"
      File.open(@log_filename, 'a') {|f| f.write(t.strftime("%m/%d/%Y %H:%M:%S")+" - "+item.to_s+" FAILED TO DOWNLOAD "+"\n") }   
   end
   
end

   puts "Do you want to exit? (y/n)"
   quit = gets.chomp
   puts ""
	end 
