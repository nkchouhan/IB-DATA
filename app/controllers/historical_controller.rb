class HistoricalController < ApplicationController
  def show
    @contract = IbContract.find(params[:id])
  end	

  def index
  	@contracts = IbContract.all
  end	
end
