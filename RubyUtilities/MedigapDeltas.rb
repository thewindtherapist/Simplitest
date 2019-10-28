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

def compareKeyArray(client, configuration, arraykeysCurrent,arraykeysPrior,outputFile)
newRecords=Array.new
deletedRecords=Array.new
id=""

deletedRecords=arraykeysCurrent - arraykeysPrior
newRecords=arraykeysPrior-arraykeysCurrent

puts "\n\t...Checking for Added rows"
puts "Total number of new records #{newRecords.length}".blue.bold
outputFile.write ("Total number of new records #{newRecords.length}")

newRecords.each do |key|
	checkForNewRecords(client,key,configuration,outputFile)
	end


puts "\n\n\t...Checking for Deleted rows"
puts "Total number of deleted records #{deletedRecords.length}".blue.bold
deletedRecords.each do |key|
	checkForDeletedRecords(client,key,configuration,outputFile)
	end
end
# Checks if record exists
def checkForNewRecords(client,key,configuration,outputFile)

	count=buildSQLstring(client,key,configuration)
	key=key.gsub("|"," ")
	 if (count==1)
		#record is added to file
			print " Has not been added to database with key of #{key}".bold.green 
	else
		 if count == 0
			 print " ERROR New record has not been added to database with key of #{key}".bold.red
			 outputFile.write ("ERROR New record has not been added to database with key of #{key}")
		 else
			 print " ERROR Too Many records found for ID of #{key}".bold.red
			 outputFile.write ("ERROR Too Many record found with IDs of #{key}")
		 end
	end 
end

#checks if record is not there
def checkForDeletedRecords(client,key,configuration,outputFile)

	count=buildSQLstring(client,key,configuration)
	key=key.gsub("|"," ")
	 if (count==0)
		#record does not exist
		puts " Has not been deleted to database with key of #{key}".bold.green 
	else
		 if count == 1
			 puts " ERROR Record has not been deleted from database with key of #{key}".bold.red
			 outputFile.write ("ERROR Record has not been deleted from database with key of #{key}")
		 else
			 puts " ERROR Too Many records found for ID of #{key}".bold.red
			 outputFile.write ("Too Many record found with IDs of #{key}")
		 end
	end 
end

def buildSQLstring(client,keyValues,configuration)
#builds where clause 
keyArray=Array.new
id=""

keyArray=keyValues.split('|')
sqlstring=configuration["sql"].clone

keyArray.each do |keystring|
     keyPos=sqlstring.index("key")	 
	 sqlstring[keyPos,3]=keystring
	 id=id+" "+keystring
	end
	
puts "Checking row #{id}".green
result=client.execute(sqlstring)
#compare results from sql to items in file
records=0
	result.each do |rowset|
	records=records+1
		end	
		
return records
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
puts " Database Delta validation script".green.bold
puts " Use Ctrl-C to stop, Ctrl-S to pause and Ctrl-Q to restart after pausing".yellow.bold
configuration=getenv()

# if no selection is made
 if configuration["sql"] == ""
	exit
end

server=configuration["server"]
databasename=configuration["databasename"]
oktorun=true

puts " Connecting to Server  #{server} and Database #{databasename}".green.bold
client = TinyTds::Client.new(:trusted_connection => 'yes', :host => server, :database => databasename)  

outputfolderFile = logFilename("#{configuration["table"]}-#{server}-#{databasename}")
puts
outputfolderFile= "../output/#{outputfolderFile}"

outputFile = File.open(outputfolderFile, "w")
outputFile.write ("Output Log file for #{configuration["table"]} on  #{server} and Database #{databasename}\n\n")

if (client.active? != true)
	oktorun=false
	puts "ERROR Problem making connection to Server  #{server} or Database #{databasename}".red.bold
	outputFile.write ("Problem with making connection to Server  #{server} or Database #{databasename}")
else
	outputFile.write ("Connecton make to Server  #{server} and Database #{databasename}")
	puts ("Connecton make to Server  #{server} and Database #{databasename}").green.bold
end

if File::exists?(configuration["filename"])
	outputFile.write ("\n Opening current file  #{configuration["filename"]}")
	puts "Opening file  #{configuration["filename"]}".green.bold
	currentfile=File.open(configuration["filename"], "r") 
else
	oktorun=false
	puts "ERROR Problem open file  #{configuration["filename"]}"
	outputFile.write ("\n ERROR Problem open file  #{configuration["filename"]}")
end

if File::exists?(configuration["prior"]) 
		outputFile.write ("\n Opening current file  #{configuration["prior"]}")
		puts "\n Opening file  #{configuration["prior"]}".green.bold
		priorfile=File.open(configuration["prior"], "r") 
	else
		oktorun=false
		puts "ERROR Problem opening file  #{configuration["prior"]}".red.bold
		outputFile.write ("\n ERROR Problem open file  #{configuration["prior"]}")
end

# do on each line from file
arrayFromLine=Array.new
arraykeysPrior=Array.new
arraykeysCurrent=Array.new
keystring=""	

if oktorun	 
	case configuration["delimiter"]
	when "\t" #process files with tab delimited
	
	puts "...Building Current Array from Key fields"
			while !currentfile.eof
				currentfile.each_line do |line|
					line=line.force_encoding('IBM437').encode('BINARY', :undef=>:replace).gsub(/[?,\x00,\r\n]/,"")
					# skip blank lines
					

					if line.length>0  
						arrayFromLine = line.to_s.split(configuration["delimiter"])						
						# only build array from fields used as keys, and keys are defined in configuration
						keystring=""
						configuration["keys"].each do |i|
						
							keystring=keystring+arrayFromLine[i]+"|"
						end #ends do statement
						arraykeysCurrent << keystring
					end #end If statement
				end #end do 
			end #ends whiles
			
			while !priorfile.eof
				priorfile.each_line do |line|
					line=line.force_encoding('IBM437').encode('BINARY', :undef=>:replace).gsub(/[?,\x00,\r\n]/,"")
					# skip blank lines
					if line.length>0  
						arrayFromLine = line.to_s.split(configuration["delimiter"])

						# only build array from fields used as keys, and keys are defined in configuration
						keystring=""
						configuration["keys"].each_with_index do |i,index|
							keystring=keystring+arrayFromLine[i]+"|"
						end 
						arraykeysPrior << keystring
					end #ends if statement
				end
			end #while

		# Now we have a array of keys from prior file and an array of keys from current file
		compareKeyArray(client, configuration, arraykeysCurrent,arraykeysPrior,outputFile)
	when "xml"  # process xml files
	when ","	#process comma seperated files
	when "col" 	#process column defined files
	end
end
outputFile.close
