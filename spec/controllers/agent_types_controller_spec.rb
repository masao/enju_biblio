require 'spec_helper'

# This spec was generated by rspec-rails when you ran the scaffold generator.
# It demonstrates how one might use RSpec to specify the controller code that
# was generated by Rails when you ran the scaffold generator.
#
# It assumes that the implementation code is generated by the rails scaffold
# generator.  If you are using any extension libraries to generate different
# controller code, this generated spec may or may not pass.
#
# It only uses APIs available in rails and/or rspec-rails.  There are a number
# of tools you can use to make these specs even more expressive, but we're
# sticking to rails and rspec-rails APIs to keep things simple and stable.
#
# Compared to earlier versions of this generator, there is very limited use of
# stubs and message expectations in this spec.  Stubs are only used when there
# is no simpler way to get a handle on the object needed for the example.
# Message expectations are only used when there is no simpler way to specify
# that an instance is receiving a specific message.

describe AgentTypesController do
  login_admin

  # This should return the minimal set of attributes required to create a valid
  # AgentType. As you add validations to AgentType, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    FactoryGirl.attributes_for(:agent_type)
  end

  describe "GET index" do
    it "assigns all agent_types as @agent_types" do
      agent_type = AgentType.create! valid_attributes
      get :index
      assigns(:agent_types).should eq(AgentType.page(1))
    end
  end

  describe "GET show" do
    it "assigns the requested agent_type as @agent_type" do
      agent_type = AgentType.create! valid_attributes
      get :show, :id => agent_type.id
      assigns(:agent_type).should eq(agent_type)
    end
  end

  describe "GET new" do
    it "assigns a new agent_type as @agent_type" do
      get :new
      assigns(:agent_type).should be_a_new(AgentType)
    end
  end

  describe "GET edit" do
    it "assigns the requested agent_type as @agent_type" do
      agent_type = AgentType.create! valid_attributes
      get :edit, :id => agent_type.id
      assigns(:agent_type).should eq(agent_type)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new AgentType" do
        expect {
          post :create, :agent_type => valid_attributes
        }.to change(AgentType, :count).by(1)
      end

      it "assigns a newly created agent_type as @agent_type" do
        post :create, :agent_type => valid_attributes
        assigns(:agent_type).should be_a(AgentType)
        assigns(:agent_type).should be_persisted
      end

      it "redirects to the created agent_type" do
        post :create, :agent_type => valid_attributes
        response.should redirect_to(AgentType.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved agent_type as @agent_type" do
        # Trigger the behavior that occurs when invalid params are submitted
        AgentType.any_instance.stub(:save).and_return(false)
        post :create, :agent_type => {}
        assigns(:agent_type).should be_a_new(AgentType)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        AgentType.any_instance.stub(:save).and_return(false)
        post :create, :agent_type => {}
        #response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested agent_type" do
        agent_type = AgentType.create! valid_attributes
        # Assuming there are no other agent_types in the database, this
        # specifies that the AgentType created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        AgentType.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, :id => agent_type.id, :agent_type => {'these' => 'params'}
      end

      it "assigns the requested agent_type as @agent_type" do
        agent_type = AgentType.create! valid_attributes
        put :update, :id => agent_type.id, :agent_type => valid_attributes
        assigns(:agent_type).should eq(agent_type)
      end

      it "redirects to the agent_type" do
        agent_type = AgentType.create! valid_attributes
        put :update, :id => agent_type.id, :agent_type => valid_attributes
        response.should redirect_to(agent_type)
      end

      it "moves its position when specified" do
        agent_type = AgentType.create! valid_attributes
        position = agent_type.position
        put :update, :id => agent_type.id, :move => 'higher'
        response.should redirect_to agent_types_url
        assigns(:agent_type).position.should eq position - 1
      end
    end

    describe "with invalid params" do
      it "assigns the agent_type as @agent_type" do
        agent_type = AgentType.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        AgentType.any_instance.stub(:save).and_return(false)
        put :update, :id => agent_type.id, :agent_type => {}
        assigns(:agent_type).should eq(agent_type)
      end

      it "re-renders the 'edit' template" do
        agent_type = AgentType.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        AgentType.any_instance.stub(:save).and_return(false)
        put :update, :id => agent_type.id, :agent_type => {}
        #response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested agent_type" do
      agent_type = AgentType.create! valid_attributes
      expect {
        delete :destroy, :id => agent_type.id
      }.to change(AgentType, :count).by(-1)
    end

    it "redirects to the agent_types list" do
      agent_type = AgentType.create! valid_attributes
      delete :destroy, :id => agent_type.id
      response.should redirect_to(agent_types_url)
    end
  end

end
