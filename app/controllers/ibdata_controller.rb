class IbdataController < ApplicationController
    
    def index
      
    end 

    def historical_data
      hash = prepare_contract params[:id]	
      fetch_historical_data hash
      redirect_to historical_path(params[:id])
    end

    def historical_data_for_all_contracts
      contract_ids = IbContract.all.map(&:id)
      contract_ids.each do |contract_id, index|
      	hash = prepare_contract contract_id
        fetch_historical_data hash
      end
      redirect_to historical_index_path
    end
    
    def prepare_contract contract_id
      contract = IbContract.find(contract_id)
      hash = {}
      contract.instance_variables.each {|var| hash[var.to_s.delete("@")] = contract.instance_variable_get(var) }
      hash = hash['attributes'].delete_if{ |k, v| v.nil? || v == '' || k == 'created_at'|| k == 'updated_at' }	
      hash['sec_type'] = hash['sec_type'].to_sym
      hash['currency'] = hash['currency'].upcase 
      hash
    end	

    def option_data
    	@market = {1 => IB::Symbols::Options[:aapl95]}

		# First, connect to IB TWS. Arbitrary :client_id is used to identify your script
		ib = IB::Connection.new :client_id => 1112 #, :port => 7496 # TWS

		## Subscribe to TWS alerts/errors
		ib.subscribe(:Alert) { |msg| puts msg.to_human }

		# Subscribe to Ticker... events.  The code passed in the block will be executed when
		# any message of that type is received, with the received message as its argument.
		# In this case, we just print out the tick.
		#
		# (N.B. The description field is not from IB TWS. It is defined
		#  locally in forex.rb, and is just arbitrary text.)
        ib.subscribe(:TickPrice, :TickSize, :TickOption, :TickString) do |msg|
		  what = @market[msg.ticker_id].description || @market[msg.ticker_id].osi
		  puts "#{msg.ticker_id}: #{what}: #{msg.to_human}"
		end

		# Now we actually request market data for the symbols we're interested in.
		@market.each_pair do |id, contract|
		  ib.send_message :RequestMarketData, :ticker_id => id, :contract => contract
		end

		puts "\nSubscribed to market data"
		puts "\n******** Press <Enter> to cancel... *********\n\n"
		STDIN.gets
		puts "Cancelling market data subscription.."

		@market.each_pair { |id, contract| ib.send_message :CancelMarketData, :id => id }
		
    end	



    private

    def fetch_historical_data contract
    	contract_id = contract['id']
    	contract = contract.delete_if{|k,v| k == 'id'}

    	@contracts = {123 => IB::Contract.new(contract)}
        
        client_id = generate_unique_client_id

        ib =  IB::Connection.new :client_id => client_id
        
        ib.subscribe(:Alert) { |msg| puts msg.to_human }

		ib.subscribe(IB::Messages::Incoming::HistoricalData) do |msg|
		   msg.results.each { |entry|
		   	entry.ib_contract_id = contract_id
			puts entry.save
		}
		  @last_msg_time = Time.now.to_i
		end
		
		@contracts.each_pair do |request_id, contract|
			ib.send_message IB::Messages::Outgoing::RequestHistoricalData.new(
		                      :request_id => request_id,
		                      :contract => contract,
		                      :end_date_time => Time.now.to_ib,
		                      :duration => '30 D', # ?
		                      :bar_size => '1 hour', # IB::BAR_SIZES.key(:hour)?
		                      :what_to_show => :trades,
		                      :use_rth => 1,
		                      :format_date => 1)
		end
		sleep 0.1 until @last_msg_time && @last_msg_time < Time.now.to_i + 0.5
	end

    def generate_unique_client_id 
      unique_client_id = nil	
      while true do
        unique_client_id = rand(1000 .. 9999)
        break  unless UniqueClientId.find_by_client_id(unique_client_id).present?
      end 
      UniqueClientId.create(client_id: unique_client_id)
      unique_client_id 
    end	

end
