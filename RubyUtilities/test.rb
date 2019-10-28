require 'nokogiri'
require 'curb'
require 'json'

require 'DBI'
require 'pp'
require 'rubygems'
require 'mysql'

server="FFX-CWS-TSTDB1"
database="Medigap"
begin
     # connect to the  server
	#con=DBI.connect("dbi:ODBC:driver={SQL Server};server=#{server};database=#{database};Trusted Connection=yes") 
	
conn=DBI.connect("DBI:mSQL:host=FFX-CWS-TSTDB1;database=Medigap;Trusted Connection=yes")
	puts conn.connected?
	
     sth = dbh.prepare("SELECT Lang_id,Lang_name FROM MEDIGAP_LANG where lang_id = ?")
     sth.execute(100)

     sth.fetch do |row|
        printf "id: %s,  Name : %s\n", row[0], row[1]

     end
     sth.finish
rescue DBI::DatabaseError => e
     puts "An error occurred"
     puts "Error code:    #{e.err}"
     puts "Error message: #{e.errstr}"
ensure
     # disconnect from server
     #con.disconnect if dbh
end