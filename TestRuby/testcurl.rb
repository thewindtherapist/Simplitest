
require 'net/https'
require 'curb'
require 'curl'
httpstring="https://staging.medicare.gov/physicianservices/Provider.svc/GetList/GETPRFGENINFO/sltdid%7C9133032105"
	
		req= Curl::Easy.new(httpstring)
		req.ssl_verify_peer = false
		req.perform do |curl| 
			curl.headers["cookie"] = "ASPSessionKey="
		end

	puts httpstring
	puts req.body_str
	puts "I am here:"
