FactoryGirl.define do
	factory :topic do
		sequence(:title) { |n| "Topic title #{n}" }
		sequence(:content) { |n| "Topic content #{n}" }
		parent_id 0
		level 0
	end
end
