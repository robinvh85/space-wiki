class Topic < ApplicationRecord
  has_many :topic_tags
  has_many :tags, :through => :topic_tags

  has_many :children, :class_name => 'Topic', :foreign_key => :parent_id
  belongs_to :parent, :class_name => 'Topic', :foreign_key => :parent_id, :required => false

  validates :title, presence: true

  def self.get_root(topic)
    if(topic.level == 1)
      topic
    else
      root_topic = topic
      while(root_topic.level > 1)
        root_topic = root_topic.parent
      end

      root_topic
    end   
  end     
end
