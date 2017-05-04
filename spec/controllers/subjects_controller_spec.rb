require 'rails_helper'

RSpec.describe SubjectsController, type: :controller do
  let(:user) { FactoryGirl.create(:user) }

  before(:all) do
    puts "Create data sample"
    FactoryGirl.create_list(:topic, 3)
  end

  before(:each) do
    sign_in user    
  end

  describe "GET #index" do
    subject { get :index }

    it "render the index template" do     
      expect(subject).to render_template :index
    end

    it "return http success" do
      expect(subject).to have_http_status(:success)
    end

    context "@subjects" do
      it do
        subject # Call get :index
        list = Topic.where(level: 0)
        binding.pry
        expect(assigns(:subjects)).to eq(list)
      end
    end

  end
end
