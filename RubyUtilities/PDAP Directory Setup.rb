# todd jones
# Test to see if directory exists

if !Dir.exists?('..\Ruby\PDAP\output')
	puts "Making Output Folder"
	system 'mkdir', '..\Ruby\PDAP\output'
else
	puts "Output Folder Exists"
end
if !Dir.exists?('..\Ruby\PDAP\current')
	puts "Making current Folder"
	system 'mkdir', '..\Ruby\PDAP\current'
else
	puts "current Folder Exists"
end

if !Dir.exists?('..\Ruby\PDAP\prior')
	puts "Making prior Folder"
	system 'mkdir', '..\Ruby\PDAP\prior'
else
	puts "prior Folder Exists"
end