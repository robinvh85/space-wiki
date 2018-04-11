class CreatePolos < ActiveRecord::Migration[5.0]
  def change
    create_table :polos do |t|
      t.string :note      
    end
  end
end
