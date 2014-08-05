class IbContractsController < ApplicationController
	def index
	  @contracts = IbContract.all 	
	end	

	def new
      @contract = IbContract.new
	end	

	def create
	  @contract = IbContract.new(params[:ib_contract]) 
	  if @contract.save!
	  	redirect_to ib_contracts_path, flash[:notice] => 'Contract created successfully'
	  else
	    render new_ib_contract_path, flash[:error] => 'There is an error while creating contract'
	  end  	
    end	

    def edit
      @contract = IbContract.find(params[:id])	
    end	

    def update
      @contract = IbContract.find(params[:id])
      if @contract.update_attributes(params[:ib_contract])	
        redirect_to ib_contracts_path, flash[:notice] => 'Contract updated successfully'
      else
      	render edit_ib_contract , flash[:error] => 'There is an error while updating contract'
      end	
    end	

    def destroy
      contract = IbContract.find(params[:id])
      if contract.destroy
      	redirect_to ib_contracts_path, flash[:notice] => 'Contract deleted successfully'
      else
      	redirect_to ib_contracts_path, flash[:error] => 'Contract not deleted successfully'
      end	
    end	
end
