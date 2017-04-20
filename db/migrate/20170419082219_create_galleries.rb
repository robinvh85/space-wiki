class CreateGalleries < ActiveRecord::Migration[5.0]
  def change
    create_table :galleries do |t|
      t.string 		:image_file_name
      t.string 		:image_content_type
      t.integer 	:image_file_size
      t.datetime 	:image_updated_at

      t.references :topic, foreign_key: true
    end
  end
end
