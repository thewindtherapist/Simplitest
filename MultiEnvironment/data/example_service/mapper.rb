module Cafe
  module Cli
    class Main
      class << self
        def map_service_results(service_results_hash)
          # Write Your mapping code goes inside this method
          # Expected Columns from query (query_result is always a hash):
          # provider_id, first_name, last_name
          # gender, address_1, address_2, city
          # state, zip, phone_number, par_status
          # accepting_new_patients, board_certification, degree
          # school_name, graduation_year
          #  service_results_hash contains the parsed json result from the service
          #  in this method, convert the service_results_hash into an array of hashes
          #  the same format as the query results
          formatted_service_results = []
          # puts service_results_hash # Uncomment this line to see the raw format of service response
          service_results_hash['GetListResult'].each do |result|
            result['AdditionalInfo'].each_with_index do |hash, index|
              formatted_service_results[index] = {} #initialize an empty hash for each result
              formatted_service_results[index]['provider_id'] = hash['Value'] if hash['Key'] == 'prvdr_id'
              formatted_service_results[index]['first_name'] = hash['Value'] if hash['Key'] == 'fst_name'
              formatted_service_results[index]['last_name'] = hash['Value'] if hash['Key'] == 'lst_name'
              formatted_service_results[index]['gender'] = hash['Value'] if hash['Key'] == 'gndr'
              formatted_service_results[index]['address_1'] = hash['Value'] if hash['Key'] == 'adrs'
              formatted_service_results[index]['address_2'] = hash['Value'] if hash['Key'] == 'adrs_2'
              formatted_service_results[index]['city'] = hash['Value'] if hash['Key'] == 'city'
              formatted_service_results[index]['state'] = hash['Value'] if hash['Key'] == 'state'
              formatted_service_results[index]['zip'] = hash['Value'] if hash['Key'] == 'zip'
              formatted_service_results[index]['phone_number'] = hash['Value'] if hash['Key'] == 'phn_nmbr'
            end
          end
          formatted_service_results # this must always be an array of hashes
        end
      end
    end
  end
end


