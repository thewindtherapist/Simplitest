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
	0 exit program"
	puts
	print 'Enter the number for the environment you are testing 0-4 ?  '.green.bold
	
	environment = gets.strip!
	case environment
		when "1"
			env = "medicare-prod-predeploy.cgifederal.com"
			valid = true
		when "2"
			env = "qa.medicare.gov"
			valid = true
		when "3"
			env = "staging.medicare.gov"
			valid = true
		when "4"
			env = "www.medicare.gov"
			valid = true
		when "5"
			env ="medicare-iterationb1.cgifederal.com"
			valid = true
		else
		  exit
	  end

   return env
end

 def testingArrays(providerID, primary, secondary,primarydesc,secondarydesc)
 errorFlag=false
 print "Checking #{providerID} "
 diffPrimary=(primary - secondary)
 diffSecondary=(secondary - primary)

 if (diffPrimary.count==0 and diffSecondary.count==0)
	print " Passed "
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
 puts "\nEnter a number between 0 and  #{$xmlresponsearray.count})".bold
 puts "0 value will test all #{$xmlresponsearray.count} records".bold
 print "What size sample would you like to test?  ".green.bold

 sample = gets.chomp!
 if (sample == "0" or sample=="") then sample=$xmlresponsearray.count end
  sample.to_i
 return sample
end

