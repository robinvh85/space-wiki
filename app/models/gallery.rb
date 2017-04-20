class Gallery < ApplicationRecord
  belongs_to :topic, :required => false

  has_attached_file :image, styles: { thumb: "200x200>" }, default_url: "/images/:style/missing.png"
  validates_attachment_content_type :image, content_type: /\Aimage\/.*\z/

  def thump_url
    image.url(:thumb)
  end

  def image_url
    image.url
  end

end
