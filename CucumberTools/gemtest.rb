#This script will check all gems defined in the array 'neededgems'
# Brent Asher 5/19/2015

	
def testforgem (gemname)
	begin
		gem gemname
		puts "Checking gem #{gemname}"
		
	rescue LoadError
		puts "Installing gem #{gemname}"
		systemstring="gem install #{gemname}"
		system(systemstring)
		Gem.clear_paths
	end
end

neededgems=Array.new
neededgems=['nokogiri', 'curb','json','tiny_tds', 'win32console','watir-webdriver']

neededgems.each do |gemname|
	testforgem(gemname)
end