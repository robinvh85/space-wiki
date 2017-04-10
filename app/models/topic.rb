class Topic < ApplicationRecord
	has_many :topic_tags
	has_many :tags, :through => :topic_tags

	has_many :children, :class_name => 'Topic', :foreign_key => :parent_id
	belongs_to :parent, :class_name => 'Topic', :foreign_key => :parent_id, :required => false

	validates :title, presence: true
end
