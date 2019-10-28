# todd jones
# Test to see if directory exists

if !Dir.exists?('..\Ruby\PHC\output')
	puts "Making Output Folder"
	system 'mkdir', '..\Ruby\PHC\output'
else
	puts "Output Folder Exists"
end
if !Dir.exists?('..\Ruby\PHC\input')
	puts "Making input Folder"
	system 'mkdir', '..\Ruby\PHC\input'
else
	puts "Input Folder Exists"
end