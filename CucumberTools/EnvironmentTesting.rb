
require 'nokogiri'
require 'win32console'
#require 'bigdecimal'
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


# Main program ###############################################
envLocation = "features/support/config"

environmentArray = Array.new
selectionArray = Array.new
startendArray= Array.new
cafeArray=Array.new

#Read all the environments in the enviroments.yml file skipping everyting that is blank or commented out

	environment = File.open("#{envLocation}/environments.yml", 'r')
	puts "\nEnvironments to run Cafe scripts\n".bold.yellow
	environment.each { |line|
		if line[0..0] == "#" 

		else
			environmentArray << line
			print " #{environmentArray.count} -> \t #{line}".bold.green

		end
	}
	
	puts "\n\nEnter Number between 0 (0 to Exit) and #{environmentArray.count} ".bold.magenta
	puts "or seperated by commans, such as 6,10,14 for specific environments".bold.magenta
	print "or use a dash for series, such as 2-5 for environments 2 through 5 etc? ".bold.magenta
	doEnvironment = gets.strip!
	if doEnvironment=="0" or doEnvironment==""
		exit
	end
	
	print "Do you wish to only executed TAGGED scripts Y/N? (blank or 0 will exit) ".bold.cyan
	doTagged = gets.strip!
	if doTagged=="0" or doTagged==""
		exit
	end
	doTagged.upcase!
	if doTagged =="Y"
		print "What is the name of the tag? (blank or 0 will exit) ".bold.cyan
		nameofTag = gets.strip!
		if nameofTag=="0" or nameofTag==""
			exit
		end
	end
	
	
	#break down selectionArray
	if doEnvironment.count(",")	> 0  #individual enviroments
	puts "Comma selecton"
		selectionArray = doEnvironment.split(",")
	else
	 if doEnvironment.count("-") > 0   #sersis environments
		puts "Dash selection"
		startendArray = doEnvironment.split("-")	
		(startendArray[0]..startendArray[1]).each do |i|
			#only add non blank environments
			if environmentArray[i.to_i-1].count(":") >0
				selectionArray << i
			end
		end
		
	 else
	 #one enviroment
	 puts "Single selection"
	 selectionArray << doEnvironment
	 end
	end

	
#Process selectionArray
selectionArray.each {|selectionNumber|

	puts "Running selected environments of #{environmentArray[selectionNumber.to_i-1]}"
	#split entries from environment.yml file
	cafeArray=environmentArray[selectionNumber.to_i-1].split(":")
	if doTagged=="Y"
		bshString="ENVIRONMENT=#{cafeArray[0]} --format html -o results#{cafeArray[0]}.html --tag @#{nameofTag}"
	else
		bshString="ENVIRONMENT=#{cafeArray[0]} --format html -o results#{cafeArray[0]}.html"
	end
	 puts "Now Running script for #{bshString}\n".bold.red
 system ("cafe run #{bshString}")
}


