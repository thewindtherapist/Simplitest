# PHC Helpers.rb is code that used globally across PHC, this code handles colors, menus, and 
# def that are used in every script across the PHC program 
# Brent Asher 5/11/2015 added shuffling to the xmlresponsearray array

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


def getenv(title)

system "cls"
	puts "\n\t #{title}".yellow.bold
	puts "\n\t1 medicare-prod-predeploy.cgifederal.com
	2 qa.medicare.gov
	3 staging.medicare.gov
	4 www.medicare.gov
	5 medicare-iterationb1.cgifederal.com
	6 medicare-iterationb2-test.cgifederal.com
	0 exit program"
	puts
	print 'Enter the number for the environment you are testing 0-4 ?  '.green.bold
	
	environment = gets.strip!
	case environment
		when "1"
			env = "medicare-prod-predeploy.cgifederal.com"
		when "2"
			env = "qa.medicare.gov"
		when "3"
			env = "staging.medicare.gov"
		when "4"
			env = "www.medicare.gov"
		when "5"
			env ="medicare-iterationb1.cgifederal.com"
		when "6"
			env ="medicare-iterationb2-test.cgifederal.com"
		else
		  exit
	  end

   return env
end

 def testingArrays(providerID, primary, secondary,primarydesc,secondarydesc)
 errorFlag=false
 print "Checking #{providerID} "
 
 # Having problems with upper and lower case 'And' switch all to lower case
 primary.each {|c| c.gsub!("AND",'and')}
 secondary.each {|c| c.gsub!("AND",'and')}

 diffPrimary=(primary - secondary)
 diffSecondary=(secondary - primary)

 if (diffPrimary.count==0 and diffSecondary.count==0)
	print " Passed ".green.bold
	$passed << providerID
else 
	print " Failed ".red.bold
	$failed << providerID
end
 
 if (diffPrimary.count)>0
	print " Missing #{diffPrimary} from #{secondarydesc}".red.bold
	$outputFile.write("FAILED Provider #{providerID} Failed Missing #{diffPrimary} from #{secondarydesc}\n")
 end
 
 if (diffSecondary.count)>0
 	print " Missing #{diffSecondary} from #{primarydesc}".red.bold
	$outputFile.write("FAILED Provider #{providerID} Failed Missing #{diffSecondary} from #{primarydesc}\n")
end
puts
 end #testingArrays
 
 def stripPhone(phn_string)
 
 phn_string.delete!("(")
 phn_string.delete!(")")
 phn_string.delete!("-")
 phn_string.delete!(" ")
 
  return phn_string
  end
  
  def countParaseXML(input_file)
# Counts records from xlm file, ask for sample size, and loads array with values from xml
puts "Counting #{input_file} as input file. Please wait..."
parser = Nokogiri::XML::SAX::Parser.new(MyDocument.new)
parser.parse(File.open(input_file))


$xmlresponsearray.shuffle!

samplesize=1000
arraycount=$xmlresponsearray.count
valid=false

 if arraycount > samplesize
	puts "Default is #{samplesize} records"
	samplesize=samplesize
else	
	puts "Default count is #{arraycount}"
	samplesize=arraycount
end

begin
puts "\nPick from three options; ".green.bold
puts "\tEnter 'A' to test all  #{arraycount} records"
puts "\tEnter 'D' to test the default number of #{samplesize} records"
puts "\tEnter 'E' to exit program"
puts "\tEnter a number between 1 and #{arraycount}"

 print "Please enter option? (ENTER for #{samplesize} records) ".green.bold
 getsample = gets.chomp!

	case getsample
		when /[EeXxQq]/
			puts "Exiting program"
			valid=true
			exit
		when /[Dd]/
			puts "Setting sample size to #{samplesize}"
			sample=samplesize
			valid=true
		when /[Aa]/
			puts "Setting sample size to #{arraycount}"
			sample=arraycount
			valid=true
		else
			if getsample.to_i.between?(1,arraycount)
				puts "Setting sample Size to #{getsample}"
				sample=getsample.to_i
				valid=true
			else
				print "Invalid Entry must be:".red.bold
				puts "Valid selections are 'A', 'E', 'D', or 1 to #{arraycount}".red.bold
			end

	end	
end while !valid
  
 return sample
end

 def buildAddressID(street, city, state, zip) 
 
 # Example Address id  <Location ADRS_ID="NC288014502AS428XXAVEX301">
 
 # Columns
 # 1-2	state (NC)
 # 3 - 7 zip  (28801)
 # 8- 11	zip extention not used (4502) 
 # 12 - 13 1st two letters of city (AS)
 # 14 - Nth 	Numeric form of address (428)
 # Street type Ave, Blvd, etc. (AVE)
 
 streetArray= Array.new 
 streetArray=street.split(" ")
 addyString=streetArray[0]
 streetType=streetArray[streetArray.count-1]
 tempString=state+zip+"0000"+city[0,2]+streetArray[0]+streetType[0..3]
 return tempString
 end
 
 def removeXs(mystring)
range=9
headstring=mystring[0...mystring.length-range]
tailstring=mystring[mystring.length-range,mystring.length]
tailstring=tailstring.gsub("X","")
tailstring=mystring[mystring.length-range,mystring.length] if tailstring == nil
tempstring=headstring+tailstring
return tempstring
end


def getSQL(title,databasename)
sqlHash=Hash.new

	puts "\n\t #{title}".yellow.bold
	puts "\n\tGroup Items
	1 Group Affilication
	2 Group Location
	3 Group Quality Programs
	4 Group Specialty
	
	Physician Items
	5 Physician Board Certification
	6 Physician Hospital Affilication
	7 Physician Languages
	8 Physician Location
	9 Physician Quality Programs
	10 Physician Residency
	11 Physician Specialty
"
	puts
	print 'Enter the number for the item to lookup in database 0-11 ?  '.green.bold
	
	environment = gets.strip!
	case environment
		when "1" #Group Affilication
			sqlHash["sql"]="SELECT [org_pac_id],a.[prvdr_id],[lst_name],[fst_name],[mdl_name]
  FROM [#{databasename}].[dbo].[PHYSN_ORG_PRVDR] a
  inner join [#{databasename}].[dbo].[PHYSN_PRVDR] b
  on a.prvdr_id =b.prvdr_id
  where a.org_pac_id="
			sqlHash["heading"]="\tGroup Pac ID\t Provider ID \tLName \tFName \t Middle Initial"
			
		when "2" #Group Location
			sqlHash["sql"]="SELECT [org_adrs_id], [org_legal_name], [adrs] ,[adrs2] ,[city] ,[state] ,[zip] ,[extzip]
  FROM [#{databasename}].[dbo].[PHYSN_ORG_ADRS] a
  inner join [#{databasename}].[dbo].[PHYSN_ADRS_LP] b
  on a.org_adrs_id = b.adrs_id
  where a.org_pac_id="
			sqlHash["heading"]="\tGroup ID\t\tGroup Name \taddress1 \taddress2 \tcity\tstate \tzip \textzip"
			
		when "3" #Group Quality Programs
			sqlHash["sql"]="SELECT [org_pac_id] ,
case when ERX_Status = 0 then 'No' else 'Yes' end ERX_status,
case when [GPRO_Status] = 0 then 'No' else 'Yes' end GPRO_Status
,[AOC_Status] ,[PQRI_Status]
  FROM [#{databasename}].[dbo].[PHYSN_ORG_QD]
		where org_pac_id="
			sqlHash["heading"]="\tGroup Pac ID\t ERX \tGRPRO \tACO \tPQRI"
			
		when "4" #Group Specialty
			sqlHash["sql"]="SELECT [org_pac_id],[spclty_name]
  FROM [#{databasename}].[dbo].[PHYSN_ORG_SPCLTY_XWALK] a
  inner join [#{databasename}].[dbo].[PHYSN_SPCLTY_LP] b
  on a.spclty_id = b.spclty_id
  where a.org_pac_id="
			sqlHash["heading"]="\tGroup Pac ID\t\t Group Specialty"
			
		when "5" #Physician Board Certification
			sqlHash["sql"]="SELECT [prvdr_id],[brd_crt_nm]
		FROM [#{databasename}].[dbo].[PHYSN_PRVDR_BRDCRT] a
		inner join [#{databasename}].[dbo].[PHYSN_BRDCRT_LKP] b
		on a.brd_crt_id = b.brd_crt_id
		where a.prvdr_id="
			sqlHash["heading"]="\tProvider ID\t\t Board Certification"
			
		when "6" #Physician Hospital Affilication
			sqlHash["sql"]="\tSELECT [prvdr_id],hsptl_name, a.[hsptl_id]
	  FROM [#{databasename}].[dbo].[PHYSN_PRVDR_HSPTL] a
	  inner join [#{databasename}].[dbo].[PHYSN_HSPTL_LP] b
	  on a.hsptl_id =b.hsptl_id
	  where a.prvdr_id="
			sqlHash["heading"]="\tProvider ID\t\t Hospital Name\t\t Hospital ID"
			
		when "7" #Physician Languages
			sqlHash["sql"]
			sqlHash["heading"]
			
		when "8" #Physician Location
			sqlHash["sql"]="SELECT [prvdr_id],a.[adrs_id],[adrs],[adrs2],[city],[state],[zip],[extzip]
  FROM [#{databasename}].[dbo].[PHYSN_PRVDR_ADRS] a
  inner join [#{databasename}].[dbo].[PHYSN_ADRS_LP] b
  on a.adrs_id = b.adrs_id
  where a.prvdr_id="
			sqlHash["heading"]="\tProvider ID\t Address ID\t address1 \taddress2 \tcity\tstate \tzip \textzip"
			
		when "9" #Physician Quality Programs
			sqlHash["sql"]="SELECT [prvdr_id]
      ,case when MOC_Status = 0 then 'No' else 'Yes' end MOC_Status
     ,case when AOC_Status = 0 then 'No' else 'Yes' end AOC_Status
      ,case when ERX_Status = 0 then 'No' else 'Yes' end ERX_Status
      ,case when PQRI_Status = 0 then 'No' else 'Yes' end PQRI_Status
      ,case when GPRO_Status = 0 then 'No' else 'Yes' end GPRO_Status
      ,case when EHR_Status = 0 then 'No' else 'Yes' end EHR_Status
      ,case when MHI_Status = 0 then 'No' else 'Yes' end MHI_Status
  FROM [#{databasename}].[dbo].[PHYSN_PRVDR_QD]
  where prvdr_id="
			sqlHash["heading"]="\tProvider ID\tMOX \tAOC \tERX \tPQRI \tGPRO \tEMR \tMHI"
			
		when "10" #Physician Residency
			sqlHash["sql"]="SELECT [prvdr_id],[rsdncy_name]    
	  FROM [#{databasename}].[dbo].[PHYSN_PRVDR_RSDNCY] a
	  inner join [#{databasename}].[dbo].[PHYSN_RSDNCY_LP] b
	  on a.rsdncy_id= b.rsdncy_id
	  where a.prvdr_id="
			sqlHash["heading"]="\tProvider ID\t\t Residency"
			
		when "11" #Physician Specialty
			sqlHash["sql"]="SELECT [prvdr_id],[spclty_name]
	  FROM [#{databasename}].[dbo].[PHYSN_PRVDR_SPCLTY] a
	  inner join [#{databasename}].[dbo].[PHYSN_SPCLTY_LP] b
	  on a.spclty_id = b.spclty_id
	where a.prvdr_id="
			sqlHash["heading"]="\tProvider ID\t\t Specialty"
		else
		  exit
	  end

   return sqlHash
end

def getServer(title)

	puts "\n\t #{title}".yellow.bold
	puts "\n\t1 ffx-cws-qadb1
	2 FFX-CWS-app3
	3 ffx-cws-tstdb1
	0 exit program"
	puts
	print 'Enter the number for the server name used for testing 0-4 ?  '.green.bold
	
	environment = gets.strip!
	case environment
		when "1"
			server = "ffx-cws-qadb1"
		when "2"
			server = "FFX-CWS-app3"
		when "3"
			server = "ffx-cws-tstdb1"
		else
		  exit
	  end

   return server
end

def getDatabase(title)

	puts "\n\t #{title}".yellow.bold
	puts "\n\t1 PhysicianCompare_Main
	2 PhysicianCompare_Prod
	3 PhysicianCompare_Offcycle
	0 exit program"
	puts
	print 'Enter the number for the server name used for testing 0-4 ?  '.green.bold
	
	environment = gets.strip!
	case environment
		when "1"
			server = "PhysicianCompare_Main"
		when "2"
			server = "PhysicianCompare_Prod"
		when "3"
			server = "PhysicianCompare_Offcycle"
		else
		  exit
	  end

   return server
end