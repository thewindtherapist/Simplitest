# SupplierDelta.rb
#
#    Program to read Supplier data file, 
#      and then compare it to an older Supplier file to find new/deleted/changed
#      records for testing. Includes file dates and record counts
#
# Created: 9/24/2013 Adam Stetser

#require 'rubygems'
#require 'net/http'
require 'zip/zipfilesystem'
require 'fileutils'



# Create log file
def logFilename(d)
   workingFile = 'Supplier_Ruby_Delta'
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
   while (line = file.gets)
      record = line[0..335]
      inputa<<record
   end
   file.close
   return(inputa)
end

# Obtain file creation time
def fileDate(file)
   fileTime = File.ctime(file)
   return fileTime
end

# Create an array of Provider ID
def getID(dataArray)
   id = Array.new
   dataArray.each do |item|
      id<<item[0..9].to_s
   end
   return id
end

#validate that only 1 zip file is in the processing folder
#def validateZipCount(zipCounter, location)
#   if zipCounter > 1
#      puts "There are more files in " + location + " than expected. Please investigated and restart."
#      exit
#   end
#   if zipCounter==0
#      puts "The zip file is missing from " + location
#      exit
#   end
#end


# Main program ###############################################
@saveLocation = "../output/"
priorLocation =  "../prior/"
currentLocation = "../current/"

urlInput = String.new
input = String.new
inputa = Array.new()
t=Time.now
logFilename(t)
filedate = t.strftime("%Y%m%d")
outputArray = Array.new
mOutputArray = Array.new
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
priorFile = "../prior/PECOS.DMEPAR.GLOB.EXTRACT"
currentFile = "../current/PECOS.DMEPAR.GLOB.EXTRACT"
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
priorLst = Dir.entries(priorLocation)
#puts priorLst
currentLst = Dir.entries(currentLocation)

# Checks if the files are identical
 if FileUtils.compare_file(priorFile, currentFile)
	puts "\n!!Warning!!\n\nThe current and prior data files are identical.\nPlease verify that the correct files were used then confirm with the technical team that the files should have the same content\nThe Delta file will be empty."
	File.open(@log_mFilename, 'w') { |f| 
		f.write("no change") }
	abort "Ending Script"
end

# Create arrays
   priorArray = loadArray(priorFile)
   priorDate = fileDate(priorFile)
   currentArray = loadArray(currentFile)
   currentDate = fileDate(currentFile)
 
  # Calculate changes between arrays. Create arrays for PID of each listing 
   deleted = priorArray - currentArray
   added = currentArray - priorArray
   deletedPID = getID(deleted)
   addedPID = getID(added)
   

   

# Determine which changed items were deleted by checking if it is exists in both added and deleted arrays
   deleted.each do |x|
      if !addedPID.include?(x[0..9].to_s)
         a = x[0..9] + " -Deleted- " + x [10..-1]
         b = " -Deleted- " + x
      else
         a = x[0..9] + " Prior     " + x [10..-1]
#         b = " Prior     " + x
      end
#      a = a.insert 151, " " #spacer between state and zip
      outputArray<<a
      if b!=nil
         mOutputArray<<b
      end
   end
 


# Determine which changed items were added by checking if it is exists in both added and deleted arrays
   added.each do |x|
      if !deletedPID.include?(x[0..9].to_s)
         a = x[0..9] + " + Added + " + x [10..-1]
         b = " + Added + " + x
      else
         a = x[0..9] +  " New Data  "+ x [10..-1]
         b = " New Data  " + x
      end
#      a = a.insert 151, " " #spacer between state and zip
      outputArray<<a
      if b!=nil
      	 mOutputArray<<b
      end
   end

# Sort the array based on Provider and change type
outputArray.sort!
mOutputArray.sort!
#puts mOutputArray

# Compute the number of adds, deletes, and changed records
outputArray.each do |x|
   if x[10..20]==" + Added + "
      adds=adds+1
   end
   if x[10..20]==" -Deleted- "
      deletes=deletes+1
   end
   if x[10..20]==" Prior     "
      changeItems=changeItems+1
      
   end
end

# Compute the number of adds, deletes, and changed records (delete prior data)
mOutputArray.each do |x|
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
   f.write("Supplier Input File Delta Report\n")
   f.write("Report Run: " + Time.now.to_s+"\n\n")
   
   f.write("Prior File name: " + priorFile + "\n") #Calculate Prior File Name
   f.write("Prior File record count excluding header: " + priorArray.size.to_s+"\n")
   f.write("Prior File Date: "+ File.mtime(priorFile).strftime("%Y/%m/%d  %H:%M:%S")+"\n\n")
   
   f.write("Current File name: " + currentFile+ "\n") #Calculate Current File Name
   f.write("Current File record count: " + currentArray.size.to_s+"\n")
   f.write("Current File Date: " + File.mtime(currentFile).strftime("%Y/%m/%d  %H:%M:%S")+"\n\n")
   
   f.write("Number of added Suppliers: " + adds.to_s+"\n")
   f.write("Number of deleted Suppliers: " + deletes.to_s+"\n")
   f.write("Number of changed Suppliers: " + changeItems.to_s+"\n\n")}
  

FileUtils.copy(@log_filename, @log_mhFilename) 

File.open(@log_filename, 'a') {|f| 
 outputArray.each do |x|
    if x[0..9]==priorPID
       f.write(x + "\n\n")
    else
       f.write("\n" + x + "\n")
    end
    priorPID = x[0..9]
 end}
  
 File.open(@log_mFilename, 'w') {|f| 
 mOutputArray.each do |x|
        f.write(x + "\n")
 end}
 
puts "Done\a"
# Clean up extracted files
#File.delete(priorLocation+priorZipFileName)
#File.delete(currentLocation+currentZipFileName)
