# Supplier Model Delta script
# Todd Jones 
# Purpose: To create a delta file to be used for SupplierModels.rb script without the need for a post-sql processed delta file.

date = Time.now
output = File.open("../output/brand_extract_delta_#{date.strftime("%Y%m%d")}.txt", 'a') # 'a' appends to existing file, 'w' overwrites 
@prior_array = Array.new
@current_array = Array.new

def load_array(input)
	supplier_array = Array.new
	brands_array = Array.new
	supplier_index = Hash.new
	brands_index = Hash.new
	models_hash = Hash.new
	supplier = File.open("../#{input}/CBIC_SUPPLIER.txt", 'r')
	brands = File.open("../#{input}/CBIC_BRANDS.txt", 'r')
	supplier.each { |line|
		supID = line[0..9]
		next if supID == "HHHHHHHHHH"
		cbsa = line[10..14]
		ctgy = line[15..17].to_i+900
		contID = line[18..27]
		phone = line[28..41]
		dba = line[42..-1].strip
		supplier_array << [contID, cbsa, ctgy, supID]
	}

	brands.each do |line|
		contID = line[0..9]
		next if contID == "HHHHHHHHHH"
		cbsa = line[10..14]
		ctgy = line[15..17].to_i+900
		mftr = line[18..272].strip
		model = line[273..-1].strip
		brands_array << [contID, cbsa, ctgy, mftr, model]
	end

	supplier_array.each do |x|
		key = "#{x[0]}#{x[1]}#{x[2]}"
		supplier_index[key] ||= []
		supplier_index[key] << x[3]
	end

	brands_array.each do |x|
		key = "#{x[0]}#{x[1]}#{x[2]}"
		brands_index[key] ||= []
		brands_index[key] << "#{x[3]}|#{x[4]}"
	end

	supplier_index.keys.each do |key|
		sup = supplier_index.fetch(key, [])
		mod = brands_index.fetch(key, [])
		models_hash[key] ||= []
		models_hash[key] << [sup, mod]
	end

	models_hash.each do |key, value|
		cbsa = key[10..14]
		ctgy = key[15..17]
		suppliers = value[0][0]
		models = value[0][1]
		suppliers.each do |supplier|
			models.each do |line|
				line = line.split("|")
				mftr = line[0]
				model = line[1]
				@prior_array << [supplier,cbsa,ctgy,mftr,model] if input == "prior"
				@current_array << [supplier,cbsa,ctgy,mftr,model] if input == "current"
			end
		end
	end
	@prior_array.sort! if input == "prior"
	@current_array.sort! if input == "current"
end

load_array("prior")
load_array("current")

deleted = @prior_array - @current_array
added = @current_array - @prior_array 

added.each do |item|
	supID = item[0]
	cbsa = item[1]
	ctgy = item[2]
	mftr = item[3]
	model = item[4]
	output.write("+ ADDED +\t#{supID}\t#{cbsa}\t#{ctgy}\t#{mftr}\t#{model}\n")
end

deleted.each do |item|
	supID = item[0]
	cbsa = item[1]
	ctgy = item[2]
	mftr = item[3]
	model = item[4]
	output.write("-DELETED-\t#{supID}\t#{cbsa}\t#{ctgy}\t#{mftr}\t#{model}\n")
end
puts "Done\a"