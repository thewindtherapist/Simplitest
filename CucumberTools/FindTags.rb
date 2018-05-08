# Find tags ruby script
# This script locates each feature file in the features/specifications/ folder no matter how many directories deep
# then determine if the first line contains a "@" sign, or has a tag. If file contains a tag the tag along with 
# the file name will be displayed, and written to file call FILETAGS.TXT.  then this file can loaded into excel 
# sorted, filtered, whatever is needed. 
# Created Brent Asher 8/18/2015
require 'win32console'
 class String
  { :reset          =>  0,
    :bold           =>  1,
    :dark           =>  2,
    :underline      =>  4,
    :blink          =>  5,
    :negative       =>  7,
    :black          => 30,
    :red            => 31,
    :green          => 32,
    :yellow         => 33,
    :blue           => 34,
    :magenta        => 35,
    :cyan           => 36,
    :white          => 37,
  }.each do |key, value|
		define_method key do
		  "\e[#{value}m" + self + "\e[0m"
		end
	end
end

newArray=Array.new
tagArray=Array.new

output = File.open("FileTags.txt", 'w') 

libfiles= File.join("**","features","**","*.feature")
newArray=Dir.glob(libfiles)
	
#output.write("Filename \t Tag Name\n\n")
newArray.each {|featurefile|
f=File.new(featurefile)
tagline=f.readline
#Found tag

if tagline.count("@") > 0
	tagline.gsub!("\n","")
	fileNameonly=featurefile.sub("features/specifications/","")
	#puts tagline +" "+ fileNameonly
	tagArray<< tagline +" "+ fileNameonly
end
f.close
}

 tagArray.sort!
puts "\nTag Name    Feature file and location\n".bold.red
 tagArray.each {|tagline|
	if tagline["@wip"]
	else
	puts "#{tagline}\n".bold.green
	end
	output.write("#{tagline}}\n")
 }
 puts "Output file of FileTags.txt has been generated ".bold.yellow