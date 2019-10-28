configuration=Hash.new

configuration["sql"]=" key word"


oldstringCLONED=configuration["sql"].clone
sqlstring=configuration["sql"]

     keyPos=sqlstring.index("key")
		puts "Hash before #{configuration["sql"]} "
		puts  "oldstringCLONED before #{oldstringCLONED}"
		puts  "sqlstring before #{sqlstring}"
	 sqlstring[keyPos,3]="000"
	 puts
		puts "A change in sqlstring, changes the hash and the other copy of the hash but not the cloned value"
	 	puts "Hash after #{configuration["sql"]}"
		puts  "oldstringCLONED after #{oldstringCLONED}"
		puts  "sqlstring after #{sqlstring}"

