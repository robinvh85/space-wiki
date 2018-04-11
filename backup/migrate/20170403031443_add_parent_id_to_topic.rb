class AddParentIdToTopic < ActiveRecord::Migration[5.0]
  def change
  	add_column :topics, :parent_id, :integer, :default => 0
  end
end
