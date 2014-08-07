class CreateUniqueClientIds < ActiveRecord::Migration
  def change
    create_table :unique_client_ids do |t|
      t.integer :client_id

      t.timestamps
    end
  end
end
