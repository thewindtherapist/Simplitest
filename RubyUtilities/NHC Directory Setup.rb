# todd jones
# Test to see if directory exists

if !Dir.exists?('..\Ruby\NHC\output')
	puts "Making Output Folder"
	system 'mkdir', '..\Ruby\NHC\output'
else
	puts "Output Folder Exists"
end
if !Dir.exists?('..\Ruby\NHC\current')
	puts "Making current Folder"
	system 'mkdir', '..\Ruby\NHC\current'
else
	puts "current Folder Exists"
end

if !Dir.exists?('..\Ruby\NHC\prior')
	puts "Making prior Folder"
	system 'mkdir', '..\Ruby\NHC\prior'
else
	puts "prior Folder Exists"
end