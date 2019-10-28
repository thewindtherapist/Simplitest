# Medigap-Database lookup

require 'nokogiri'
require 'curb'
require 'json'
require 'win32console'
require_relative 'MedigapHelper'
require 'tiny_tds'


$outputFile = File.open("../output/Medigap-Database Lookup #{Time.now.strftime("%Y%m%d")}.txt", 'w')
  
# Main body of script 
sqlHash=Hash.new

server="FFX-CWS-app3"
databasename="Medigap"
system("cls")
puts "Medigap-Database lookup".green.bold
$outputFile.write "Medigap-Database lookup \n\n"
sqlHash=getenv()

sqlstring=sqlHash["sql"]
idstring=""

sqlHash["titles"].each do |title|
	print "Enter #{title} " 
	id=gets.strip!
	keyPos=sqlstring.index("key")	
	sqlstring[keyPos,3]=id
	 idstring=idstring+" "+id
end
	
#Loads specialties into an array from database table
puts " \t\n Connecting to Server  #{server} and Database #{databasename}\n\n"
client = TinyTds::Client.new(:trusted_connection => 'yes', :host => server, :database => databasename) 

# Display each item with tab between

		result=client.execute(sqlstring)
		result.do
		# puts result.fields
		# puts result.fields.count
		# puts "return code"
		
		# puts "code equals to null "  if client.return_code == nil
		# puts "code is not equal to null " if client.return_code != nil
		
		numberofRecords=result.affected_rows
		
		if numberofRecords > 0 
			result=client.execute(sqlstring)
			puts sqlstring
			puts "\n"
			$outputFile.write(sqlstring)
			$outputFile.write("\n\n")
			
			puts "\tFound #{numberofRecords} records\n".bold.green
			$outputFile.write("\tFound #{numberofRecords} records\n")
			$outputFile.write("\n\n")
			
			# Display Headings
			puts sqlHash["heading"]
			$outputFile.write(sqlHash["heading"]+"\n")
			
			result.each do |row| 
			  result.fields.each do |fieldname|
					 print "\t"
					 $outputFile.write("\t")
					  if row[fieldname] != nil
						print row[fieldname].to_s
						$outputFile.write(row[fieldname])
					  else
						print "Nill"
						$outputFile.write("Nill")
					  end				
					$outputFile.write("\t")
				end
				print "\n"
				$outputFile.write("\n")
			end	
		else
			puts "\tNo reoord is found".bold.red
		end

$outputFile.close