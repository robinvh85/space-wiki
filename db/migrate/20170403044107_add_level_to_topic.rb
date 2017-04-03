class AddLevelToTopic < ActiveRecord::Migration[5.0]
  def change
  	add_column :topics, :level, :integer, :default => 0
  end
end
