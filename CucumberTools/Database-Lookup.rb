# Database lookup

require 'nokogiri'
require 'curb'
require 'json'
require 'win32console'
require_relative 'ToolHelpers'
require 'tiny_tds'

$outputFile = File.open("../output/Database Lookup #{Time.now.strftime("%Y%m%d")}.txt", 'w')
add_XML = "../input/group_Add.xml"
  
# Main body of script 
sqlHash=Hash.new
server=getServer("Server Name")
databasename=getDatabase("Database Name")
sqlHash=getSQL("Database lookup",databasename)

$outputFile.write "Database lookup \n\n"

	print "Enter ID to lookup? "
	id=gets.strip!
	sqlstring=sqlHash["sql"]+ "'"+ id +"'"


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
						print row[fieldname]
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