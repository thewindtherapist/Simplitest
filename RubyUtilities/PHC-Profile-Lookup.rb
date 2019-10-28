
require 'nokogiri'
require 'curb'
require 'json'
require 'win32console'
require 'watir-webdriver'
require_relative 'PHCToolHelpers'

#http://staging.medicare.gov/physiciancompare/group-profile.html#selectedID=7810922077&prev=results&rNum=0|1|5

# Main body of script
	starttime=Time.now
	Tool="/physiciancompare"
	env=getenv("Physician Profile Lookup")
	
	print "Enter ID to lookup? "
	id=gets.strip!
	print "Enter 1 for provider or 2 for Group lookup 0 to exit ?" 
	prvOrGroup = gets.strip!
	case prvOrGroup
		when "1"
			url = "http://#{env}#{Tool}/profile.html#selectedID=#{id}"
		when "2"
			url = "http://#{env}#{Tool}/group-profile.html#selectedID=#{id}"
			else
		  exit
	  end
	  puts url
	
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
	  
	 #system("start #{url}")