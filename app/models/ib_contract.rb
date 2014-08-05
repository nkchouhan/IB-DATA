class IbContract < ActiveRecord::Base  
	has_many :ib_bars
	attr_accessible :con_id, :sec_type, :strike, :currency, :sec_id_type, :sec_id, :legs_description, :symbol, :local_symbol, :multiplier, :expiry, :exchange, :primary_exchange, :include_expired, :right, :type 
end