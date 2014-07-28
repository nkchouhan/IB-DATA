class IbdataController < ApplicationController
	def historical_data
       @contracts = {123 => IB::Symbols::Stocks[:vxx]}

		# Connect to IB TWS.
		ib = IB::Connection.new :client_id => 1112 #, :port => 7496 # TWS

		# Subscribe to TWS alerts/errors
		ib.subscribe(:Alert) { |msg| puts msg.to_human }

		# Subscribe to HistoricalData incoming events. The code passed in the block
		# will be executed when a message of that type is received, with the received
		# message as its argument. In this case, we just print out the data.
		#
		# Note that we have to look the ticker id of each incoming message
		# up in local memory to figure out what it's for.
		ib.subscribe(IB::Messages::Incoming::HistoricalData) do |msg|
		  debugger
		  puts @contracts[msg.request_id].description + ": #{msg.count} items:"
		  msg.results.each { |entry| puts " #{entry}" }
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
		puts "\n******** Press <Enter> to exit... *********\n\n"
        STDIN.gets

    end

    def option_data
    	@market = {1 => IB::Symbols::Options[:wfc20],
           2 => IB::Symbols::Options[:z50],
           3 => IB::Symbols::Options[:spy75],
           4 => IB::Symbols::Options[:spy100]}

		# First, connect to IB TWS. Arbitrary :client_id is used to identify your script
		ib = IB::Connection.new :client_id => 1112 #, :port => 7496 # TWS

		## Subscribe to TWS alerts/errors
		ib.subscribe(:Alert) { |msg| puts msg.to_human }

		# Subscribe to Ticker... events. The code passed in the block will be executed when
		# any message of that type is received, with the received message as its argument.
		# In this case, we just print out the tick.
		#
		# (N.B. The description field is not from IB TWS. It is defined
		# locally in forex.rb, and is just arbitrary text.)
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

end
