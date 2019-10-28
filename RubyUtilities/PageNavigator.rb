
require 'nokogiri'
require 'win32console'
#require 'bigdecimal'
require 'win32console'
require 'watir-webdriver'


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
pageArray= Array.new
cafeArray= Array.new

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
	
	print "\n\nEnter Number between 0 (0 to Exit) and #{environmentArray.count} ".bold.magenta
	doEnvironment = gets.strip!
	if doEnvironment=="0" or doEnvironment==""
		exit
	end
	
	#Read all the page in the page.yml file skipping everyting that is blank or commented out

	page = File.open("#{envLocation}/pages.yml", 'r')
	puts "\Page to run Cafe scripts\n".bold.yellow
	page.each { |line|
		if line[0..0] == "#" 

		else
			pageArray << line
			puts " #{pageArray.count} ->  #{line[0..100]}".bold.green

		end
	}
		print "\n\nEnter Number between 0 (0 to Exit) and #{pageArray.count} ".bold.magenta
	doPage = gets.strip!
	if doPage=="0" or doPage==""
		exit
	end
	
	puts environmentArray[doEnvironment.to_i-1]
	puts pageArray[doPage.to_i-1]
	
	rooturl=environmentArray[doEnvironment.to_i-1].index(":")+1
	envurl=environmentArray[doEnvironment.to_i-1][rooturl..environmentArray[doEnvironment.to_i-1].length]
	
	pageurl= pageArray[doPage.to_i-1].index(":")+1
	weburl=pageArray[doPage.to_i-1][pageurl..pageArray[doPage.to_i-1].length]
	
	url=envurl+weburl
	url.gsub!(/\n/,'')
	url.gsub!('"','')
	url.gsub!(' ','')
	
	print "The URL for the browser is #{url}\n"
	
	print "\nSelect Browser, I for Internet Explorer, C for Chrome (Default) F for Filefox? ".green.bold
	selectBrw=gets.strip!.upcase
	  	case selectBrw
		when "I"
			brw=Watir::Browser.new :ie
		when "F"
			brw=Watir::Browser.new :firefox
		when "C"
			brw=Watir::Browser.new :chrome
		else
			brw=Watir::Browser.new :chrome
	  end
	  
	   brw.goto url