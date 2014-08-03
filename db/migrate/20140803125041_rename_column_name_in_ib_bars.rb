class RenameColumnNameInIbBars < ActiveRecord::Migration
  def up
  	rename_column :ib_bars, :contract_id, :ib_contract_id
  end

  def down
  	rename_column :ib_bars, :ib_contract_id  ,:contract_id
  end
end
