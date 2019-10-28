# NhcDelta.rb
#
#    Program to read NHC data zip file, extract Provider file
#      and then compare it to an older NHC file to find new/deleted/changed
#      records for testing. Includes file dates and record counts
#
#    NOTE: Use WinZip to unzip the raw data files or else the File Dates will not be correct(7Zip loses this info)

# Created: 1/29/2013 Adam Stetser

require 'zip/zipfilesystem'
require 'nokogiri'


# Create log file
def logFilename(d)
   workingFile = 'NHC_Ruby_Delta'
   filedate = d.strftime("%Y%m%d")
   local_filename2 = '.txt'
   @log_filename = @saveLocation+workingFile+filedate+local_filename2
   @log_mFilename = @saveLocation+workingFile+"Auto"+filedate+local_filename2
   @log_mhFilename = @saveLocation+workingFile+"HeaderAuto"+filedate+local_filename2
end

# Create array from input file
def loadArray(item)
   inputa = Array.new

   file = File.open(item, "r")
   x = 5000
   while (line = file.gets)
      provider = Array.new
      provider_input = Array.new
      record = String.new
      provider_input = line.to_s.split(/\t/)
      provider = provider_input.first(11)#7
      provider.each do |element|
			element = element.gsub("&amp;", "&")
           record=record+element
           record=record+"\t"
      end
      inputa<<record
   end
   file.close
  
   return(inputa)
end

# Obtain file creation time
def fileDate(file)
   fileTime = File.mtime(file)
   return fileTime
end

# Create an array of Provider ID
def getID(dataArray)
   id = Array.new
   dataArray.each do |item|
      id<<item[0..6].to_s
   end
   return id
end

#validate that only 1 zip file is in the processing folder
def validateZipCount(zipCounter, location)
   if zipCounter > 1
      puts "There are more files in " + location + " than expected. Please investigated and restart."
      exit
   end
   if zipCounter==0
      puts "The zip file is missing from " + location
      exit
   end
end

# Convert XML inputs for prior and current to text files used by the loadarray method
def parse(input_file, output_location)
	outputFile = File.open("../#{output_location}/NH_RESULTS.txt", 'w') 
	puts "Parsing #{output_location} data. Please wait..."
	doc = Nokogiri::XML(File.read(input_file))
	puts "Provider count for #{output_location} file: #{doc.xpath("//Provider").count}"
	doc.xpath("//Provider").each do |provider|
		outputFile.write("#{provider["PID"]}\t")
		['ProviderName', 'AddressLine1', 'AddressCity', 'AddressState', 'AddressPostalCode', 'TelephoneNumber', 'OVERALL_RATING', 'INSPECTION_RATING', 'STAFFING_RATING', 'QUALITY_RATING'].each do |el| #
			outputFile.write("#{provider.at(el).inner_html}\t")
		end
		outputFile.write("\n")
	end
end

# Main program ###############################################
@saveLocation = "../output/"
priorLocation =  "../prior/"
currentLocation = "../current/"
pXMLin = "../prior/NHResXMLOut.xml"
cXMLin = "../current/NHResXMLOut.xml"
urlInput = String.new
input = String.new
inputa = Array.new()
t=Time.now
logFilename(t)
filedate = t.strftime("%m%d%Y")
@outputArray = Array.new
@mOutputArray = Array.new
changeItems = 0
adds = 0
deletes = 0
mChangeItems = 0
mAdds = 0
mDeletes = 0
priorPID = "0"
priorFileArray = Array.new
currentFileArray = Array.new
priorZipFileName = String.new

# Access data files
priorFile = "../prior/NH_RESULTS.txt"
currentFile = "../current/NH_RESULTS.txt"

if !File.directory?(priorLocation)
   puts "The folder requested "+priorLocation+ " does not exist, please investigate"
   exit
end
if !File.directory?(currentLocation)
   puts "The folder requested "+currentLocation+ " does not exist, please investigate"
   exit
end
if !File.directory?(@saveLocation)
   puts "The folder requested "+ @saveLocation + " does not exist, please investigate"
   exit
end

parse(cXMLin, "current")
parse(pXMLin, "prior")

# Create arrays   
   priorArray = loadArray(priorFile) #priorLocation+priorZipFileName)
   priorDate = fileDate(priorFile) #priorLocation+priorZipFileName) ## Need to change this so it pulls date from inside ZIPFILE
   currentArray = loadArray(currentFile) #currentLocation+currentZipFileName)
   currentDate = fileDate(currentFile) #currentLocation+currentZipFileName) ## Need to change this so it pulls date from inside ZIPFILE

  # Calculate changes between arrays. Create arrays for PID of each listing 
   deleted = priorArray - currentArray
   added = currentArray - priorArray
   deletedPID = getID(deleted)
   addedPID = getID(added)

# Determine which changed items were deleted by checking if it is exists in both added and deleted arrays
   deleted.each do |x|
      if !addedPID.include?(x[0..6].to_s)
         a = x[0..5] + " -Deleted- " + x[6..-1]
         b = " -Deleted- " + x
      else
         a = x[0..5] + " Prior     " + x[6..-1]
      end
#      x.insert 151, " " #spacer between state and zip
      @outputArray<<a
      if b!=nil
         @mOutputArray<<b
      end

   end
 


# Determine which changed items were added by checking if it is exists in both added and deleted arrays
   added.each do |x|
      if !deletedPID.include?(x[0..6].to_s)
         a = x[0..5] + " + Added + " + x[6..-1]
         b = " + Added + " + x
      else
         a = x[0..5] + " New Data  " + x[6..-1]
         b = " New Data  " + x
      end
#      x.insert 151, " " #spacer between state and zip
      @outputArray<<a
      if b!=nil
      	 @mOutputArray<<b
      end
   end

# Sort the array based on Provider and change type
@outputArray.sort!
@mOutputArray.sort!

# Compute the number of adds, deletes, and changed records
@outputArray.each do |x|
   if x[6..16]==" + Added + "
      adds=adds+1
   end
   if x[6..16]==" -Deleted- "
      deletes=deletes+1
   end
   if x[6..16]==" New Data  "
      changeItems=changeItems+1
   end
end

# Compute the number of adds, deletes, and changed records (delete prior data)
@mOutputArray.each do |x|
   if x[0..10]==" + Added + "
      mAdds=mAdds+1
   end
   if x[0..10]==" -Deleted- "
      mDeletes=mDeletes+1
   end
   if x[0..10]==" New Data  "
      mChangeItems=mChangeItems+1
      
   end
end

#
#   Generate Report
#

File.open(@log_filename, 'w') {|f| 
   f.write("NHC Input File Delta Report\n")
   f.write("Report Run: " + Time.now.to_s+"\n\n")
   
   f.write("Prior File name: " + priorFile + "\n") #Calculate Prior File Name
   f.write("Prior File record count excluding header: " + (priorArray.size).to_s+"\n")
   f.write("Prior File Date: "+ File.mtime(pXMLin).strftime("%m/%d/%Y  %H:%M:%S")+"\n\n")
   
   f.write("Current File name: " + currentFile + "\n") #Calculate Current File Name
   f.write("Current File record count excluding header: " + (currentArray.size).to_s+"\n")
   f.write("Current File Date: " + File.mtime(cXMLin).strftime("%m/%d/%Y  %H:%M:%S")+"\n\n")
   
   f.write("Number of added Providers: " + adds.to_s+"\n")
   f.write("Number of deleted Providers: " + deletes.to_s+"\n")
   f.write("Number of changed Providers: " + changeItems.to_s+"\n\n")

}
FileUtils.copy(@log_filename, @log_mhFilename) 


File.open(@log_filename, 'a') {|f| 
 @outputArray.each do |x|
 
    if x[6..16]==" + Added + "
       f.write(x + "\n\n")
    end
    if x[6..16]==" -Deleted- "
       f.write(x + "\n\n")
    end
    if x[6..16]==" New Data  "
       f.write(x + "\n")
    end
    if x[6..16]==" Prior     "
        f.write(x + "\n\n")
    end
 end}

File.open(@log_mFilename, 'w') {|f| 
  @mOutputArray.each do |x|
         f.write(x + "\n")
end}
