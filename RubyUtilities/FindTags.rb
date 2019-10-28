# Find tags ruby script
# This script locates each feature file in the features/specifications/ folder no matter how many directories deep
# then determine if the first line contains a "@" sign, or has a tag. If file contains a tag the tag along with 
# the file name will be displayed, and written to file call FILETAGS.TXT.  then this file can loaded into excel 
# sorted, filtered, whatever is needed. 
#Created Brent Asher 8/18/2015

newArray=Array.new
output = File.open("FileTags.txt", 'w') 

libfiles= File.join("**","features","**","*.feature")
newArray=Dir.glob(libfiles)
	
#output.write("Filename \t Tag Name\n\n")
newArray.each {|featurefile|
f=File.new(featurefile)
tagline=f.readline
#Found tag
if tagline.count("@")>0
	tagline.gsub!("\n","")
	fileNameonly=featurefile.sub("features/specifications/","")
	output.write("#{tagline} \t #{fileNameonly}\n")
	puts "#{tagline}\t #{fileNameonly}"
end
f.close
}

