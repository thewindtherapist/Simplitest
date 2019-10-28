require 'nokogiri'
require 'curb'
require 'json'
require 'tiny_tds'
require_relative 'MedigapHelper'
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

def compareDatabaseToArray(client, configuration, downloadItems,outputFile)
fieldsarray=Array.new
databaseArray=Array.new
id=""

# excute sql first time to get name of fields
sqlstring=configuration["sql"].clone
result=client.execute(sqlstring)
fieldsarray=result.fields
 
#builds where clause 
 configuration["keys"].each_with_index do |keystring,index|
     keyPos=sqlstring.index("key")
	 sqlstring[keyPos,3]=downloadItems[keystring]
	 id=id+" "+downloadItems[keystring]
	end
	 print "\nChecking #{id}"
	 #Executes sql with where clause with keys 
result=client.execute(sqlstring)
#compare results from sql to items in file
records=0
	result.each do |rowset|
	records=records+1
		fieldsarray.each do |hashname|
				databaseArray << rowset[hashname].to_s.gsub(",","")
				end
		end	
		
# Only want one record based on key fields, if 0 or more than one then error
if (records==1)
	checkArrays(id,fieldsarray,outputFile,databaseArray," From Database ", downloadItems, " Update File")
else
	if records == 0
		puts " No record found for ID of #{id.bold.red}"
		outputFile.write ("No record found with IDs of #{id}")
	else
		puts " Too Many records found for ID of #{id.bold.red}"
		outputFile.write ("Too Many record found with IDs of #{id}")
	end
end 

end	
 
 def checkArrays (id,fieldsarray,outputFile,array1, message1, array2, message2)
 
smallestCount=0
# if array size is not equal use the smallest count to avoid errors
smallestCount=array1.count if array1.count <= array2.count
smallestCount=array2.count if array2.count <= array1.count

(0..smallestCount-1).each do |i|
# print "Checking field "
 #puts  fieldsarray[i]
 print "."
	if array1[i] != array2[i]

		puts "The value of #{array1[i].bold.red} in #{message1} expected #{array2[i].bold.yellow} from #{message2} for field #{fieldsarray[i]} \n"
		outputFile.write ("For ID #{id} The value of #{array1[i]} in #{message1} expected #{array2[i]} from #{message2} for field #{fieldsarray[i]} \n")
		end 	
 end

end

 # Create log file title with date
def logFilename(filename)
   workingFile = filename
   filedate = Time.now.strftime("%Y%m%d")
   local_filename2 = '.txt'
   log_filename = workingFile+filedate+local_filename2
   puts log_filename
return log_filename
end


### MAIN PROGRAM ###
configuration=Hash.new
puts
puts
puts " \t  Database Refresh validation script".green.bold
puts " Use Ctrl-C to stop, Ctrl-S to pause and Ctrl-Q to restart after pausing".yellow.bold
configuration=getenv()

# if no selection is made
 if configuration["sql"] == ""
	exit
end

server=configuration["server"]
databasename=configuration["databasename"]
oktorun=true

puts " \t Connecting to Server  #{server} and Database #{databasename}"
client = TinyTds::Client.new(:trusted_connection => 'yes', :host => server, :database => databasename)  

outputfolderFile = logFilename("#{configuration["table"]}-#{server}-#{databasename}")
puts
outputfolderFile= "../output/#{outputfolderFile}"

outputFile = File.open(outputfolderFile, "w")
outputFile.write ("Output Log file for #{configuration["table"]} on  #{server} and Database #{databasename}\n\n")

if (client.active? != true)
	oktorun=false
	puts "ERROR Problem making connection to Server  #{server} or Database #{databasename}"
	outputFile.write ("Problem with making connection to Server  #{server} or Database #{databasename}")
else
	outputFile.write ("Connecton make to Server  #{server} and Database #{databasename}")
	puts ("Connecton make to Server  #{server} and Database #{databasename}")
end

file=File.open(configuration["filename"], "r")
if file.eof? == true
	oktorun=false
	puts "ERROR Problem open file  #{configuration["filename"]}"
	outputFile.write ("\n ERROR Problem open file  #{configuration["filename"]}")
else
	outputFile.write ("\n Opening file  #{configuration["filename"]}")
	puts "\n Opening file  #{configuration["filename"]}"
end
# do on each line from file
arrayFromLine=Array.new
if oktorun	 
	case configuration["delimiter"]
	when "\t" #process files with tab delimited
			while !file.eof
				file.each_line do |line|
					line=line.force_encoding('IBM437').encode('BINARY', :undef=>:replace).gsub(/[?,\x00,\r\n]/,"")
					# skip blank lines
					if line.length>0  
						arrayFromLine = line.to_s.split(configuration["delimiter"])
						compareDatabaseToArray(client,  configuration, arrayFromLine, outputFile)
					end
					end 
			end 
	when "xml"  # process xml files
	when ","	#process comma seperated files
	when "col" 	#process column defined files
	end
end
outputFile.close
