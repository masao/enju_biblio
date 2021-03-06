require 'spec_helper'

describe AgentsController do
  fixtures :all

  def valid_attributes
    FactoryGirl.attributes_for(:agent)
  end

  describe "GET index" do
    before do
      Agent.__elasticsearch__.create_index!
      Agent.import
    end

    describe "When logged in as Administrator" do
      login_fixture_admin

      it "assigns all agents as @agents" do
        get :index
        assigns(:agents).should_not be_empty
      end

      it "should get index with agent_id" do
        get :index, :agent_id => 1
        response.should be_success
        assigns(:agent).should eq Agent.find(1)
        assigns(:agents).should eq assigns(:agent).derived_agents.where('required_role_id >= 1').page(1)
      end

      it "should get index with query" do
        get :index, :query => 'Librarian1'
        assigns(:agents).should_not be_empty
        response.should be_success
      end
    end

    describe "When logged in as Librarian" do
      login_fixture_librarian

      it "assigns all agents as @agents" do
        get :index
        assigns(:agents).should_not be_empty
      end
    end

    describe "When logged in as User" do
      login_fixture_user

      it "assigns all agents as @agents" do
        get :index
        assigns(:agents).should_not be_empty
      end
    end

    describe "When not logged in" do
      it "assigns all agents as @agents" do
        get :index
        assigns(:agents).should_not be_empty
      end

      it "assigns all agents as @agents in rss format" do
        get :index, :format => :rss
        assigns(:agents).should_not be_empty
      end

      it "assigns all agents as @agents in atom format" do
        get :index, :format => :atom
        assigns(:agents).should_not be_empty
      end

      it "should get index with agent_id" do
        get :index, :agent_id => 1
        response.should be_success
        assigns(:agent).should eq Agent.find(1)
        assigns(:agents).should eq assigns(:agent).derived_agents.where(:required_role_id => 1).page(1)
      end

      it "should get index with manifestation_id" do
        get :index, :manifestation_id => 1
        assigns(:manifestation).should eq Manifestation.find(1)
        assigns(:agents).should eq assigns(:manifestation).publishers.where(:required_role_id => 1).page(1)
      end

      it "should get index with query" do
        get :index, :query => 'Librarian1'
        assigns(:agents).should be_empty
        response.should be_success
      end
    end
  end

  describe "GET show" do
    before(:each) do
      @agent = FactoryGirl.create(:agent)
    end

    describe "When logged in as Administrator" do
      login_fixture_admin

      it "assigns the requested agent as @agent" do
        get :show, :id => @agent.id
        assigns(:agent).should eq(@agent)
      end
    end

    describe "When logged in as Librarian" do
      login_fixture_librarian

      it "assigns the requested agent as @agent" do
        get :show, :id => @agent.id
        assigns(:agent).should eq(@agent)
      end

      #it "should show agent when required_role is user" do
      #  get :show, :id => users(:user2).agent.id
      #  assigns(:agent).should eq(users(:user2).agent)
      #  response.should be_success
      #end

      #it "should show_ atron when required_role is librarian" do
      #  get :show, :id => users(:user1).agent.id
      #  assigns(:agent).should eq(users(:user1).agent)
      #  response.should be_success
      #end

      it "should not show agent who does not create a work" do
        lambda{
          get :show, :id => 3, :work_id => 3
        }.should raise_error(ActiveRecord::RecordNotFound)
        #response.should be_missing
      end

      it "should not show agent who does not produce a manifestation" do
        lambda{
          get :show, :id => 4, :manifestation_id => 4
        }.should raise_error(ActiveRecord::RecordNotFound)
        #response.should be_missing
      end

      #it "should not show agent when required_role is 'Administrator'" do
      #  sign_in users(:librarian2)
      #  get :show, :id => users(:librarian1).agent.id
      #  response.should be_forbidden
      #end
    end

    describe "When logged in as User" do
      login_fixture_user

      it "assigns the requested agent as @agent" do
        get :show, :id => @agent.id
        assigns(:agent).should eq(@agent)
      end

      #it "should show user" do
      #  get :show, :id => users(:user2).agent.id
      #  assigns(:agent).required_role.name.should eq 'User'
      #  response.should be_success
      #end

      #it "should not show agent when required_role is 'Librarian'" do
      #  sign_in users(:user2)
      #  get :show, :id => users(:user1).agent.id
      #  response.should be_forbidden
      #end
    end

    describe "When not logged in" do
      it "assigns the requested agent as @agent" do
        get :show, :id => @agent.id
        assigns(:agent).should eq(@agent)
      end

      it "should show agent with work" do
        get :show, :id => 1, :work_id => 1
        assigns(:agent).should eq assigns(:work).creators.first
      end

      it "should show agent with manifestation" do
        get :show, :id => 1, :manifestation_id => 1
        assigns(:agent).should eq assigns(:manifestation).publishers.first
      end

      it "should not show agent when required_role is 'User'" do
        get :show, :id => 5
        response.should redirect_to new_user_session_url
      end
    end
  end

  describe "GET new" do
    describe "When logged in as Administrator" do
      login_fixture_admin

      it "assigns the requested agent as @agent" do
        get :new
        assigns(:agent).should_not be_valid
      end
    end

    describe "When logged in as Librarian" do
      login_fixture_librarian

      it "assigns the requested agent as @agent" do
        get :new
        assigns(:agent).should_not be_valid
      end
    end

    describe "When logged in as User" do
      login_fixture_user

      it "should not assign the requested agent as @agent" do
        get :new
        assigns(:agent).should_not be_valid
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "should not assign the requested agent as @agent" do
        get :new
        assigns(:agent).should_not be_valid
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "GET edit" do
    describe "When logged in as Administrator" do
      login_fixture_admin

      it "assigns the requested agent as @agent" do
        agent = Agent.find(1)
        get :edit, :id => agent.id
        assigns(:agent).should eq(agent)
      end
    end

    describe "When logged in as Librarian" do
      login_fixture_librarian

      it "assigns the requested agent as @agent" do
        agent = Agent.find(1)
        get :edit, :id => agent.id
        assigns(:agent).should eq(agent)
      end

      #it "should edit agent when its required_role is 'User'" do
      #  get :edit, :id => users(:user2).agent.id
      #  response.should be_success
      #end

      #it "should edit agent when its required_role is 'Librarian'" do
      #  get :edit, :id => users(:user1).agent.id
      #  response.should be_success
      #end
  
      #it "should edit admin" do
      #  get :edit, :id => users(:admin).agent.id
      #  response.should be_forbidden
      #end
    end

    describe "When logged in as User" do
      login_fixture_user

      it "assigns the requested agent as @agent" do
        agent = Agent.find(1)
        get :edit, :id => agent.id
        response.should be_forbidden
      end

      #it "should edit myself" do
      #  get :edit, :id => users(:user1).agent.id
      #  response.should be_success
      #end

      #it "should not edit other user's agent profile" do
      #  get :edit, :id => users(:user2).agent.id
      #  response.should be_forbidden
      #end
    end

    describe "When not logged in" do
      it "should not assign the requested agent as @agent" do
        agent = Agent.find(1)
        get :edit, :id => agent.id
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "POST create" do
    before(:each) do
      @attrs = valid_attributes
      @invalid_attrs = FactoryGirl.attributes_for(:agent, :full_name => '')
    end

    describe "When logged in as Administrator" do
      login_fixture_admin

      describe "with valid params" do
        it "assigns a newly created agent as @agent" do
          post :create, :agent => @attrs
          assigns(:agent).should be_valid
        end

        it "redirects to the created agent" do
          post :create, :agent => @attrs
          response.should redirect_to(agent_url(assigns(:agent)))
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved agent as @agent" do
          post :create, :agent => @invalid_attrs
          assigns(:agent).should_not be_valid
        end

        it "re-renders the 'new' template" do
          post :create, :agent => @invalid_attrs
          response.should render_template("new")
        end
      end
    end

    describe "When logged in as Librarian" do
      login_fixture_librarian

      describe "with valid params" do
        it "assigns a newly created agent as @agent" do
          post :create, :agent => @attrs
          assigns(:agent).should be_valid
        end

        it "redirects to the created agent" do
          post :create, :agent => @attrs
          response.should redirect_to(agent_url(assigns(:agent)))
        end

        it "should create a relationship if work_id is set" do
          post :create, :agent => @attrs, :work_id => 1
          response.should redirect_to(agent_url(assigns(:agent)))
          assigns(:agent).works.should eq [Manifestation.find(1)]
        end

        it "should create a relationship if manifestation_id is set" do
          post :create, :agent => @attrs, :manifestation_id => 1
          response.should redirect_to(agent_url(assigns(:agent)))
          assigns(:agent).manifestations.should eq [Manifestation.find(1)]
        end

        it "should create a relationship if item_id is set" do
          post :create, :agent => @attrs, :item_id => 1
          response.should redirect_to(agent_url(assigns(:agent)))
          assigns(:agent).items.should eq [Item.find(1)]
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved agent as @agent" do
          post :create, :agent => @invalid_attrs
          assigns(:agent).should_not be_valid
        end

        it "re-renders the 'new' template" do
          post :create, :agent => @invalid_attrs
          response.should render_template("new")
        end
      end

      # TODO: full_name以外での判断
      it "should create agent without full_name" do
        post :create, :agent => { :first_name => 'test' }
        response.should redirect_to agent_url(assigns(:agent))
      end
    end

    describe "When logged in as User" do
      login_fixture_user

      describe "with valid params" do
        it "assigns a newly created agent as @agent" do
          post :create, :agent => @attrs
          assigns(:agent).should be_valid
        end

        it "should be forbidden" do
          post :create, :agent => @attrs
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved agent as @agent" do
          post :create, :agent => @invalid_attrs
          assigns(:agent).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :agent => @invalid_attrs
          response.should be_forbidden
        end
      end

      #it "should not create agent myself" do
      #  post :create, :agent => { :full_name => 'test', :user_username => users(:user1).username }
      #  assigns(:agent).should_not be_valid
      #  response.should be_success
      #end

      #it "should not create other agent" do
      #  post :create, :agent => { :full_name => 'test', :user_id => users(:user2).username }
      #  response.should be_forbidden
      #end
    end

    describe "When not logged in" do
      describe "with valid params" do
        it "assigns a newly created agent as @agent" do
          post :create, :agent => @attrs
          assigns(:agent).should be_valid
        end

        it "should be forbidden" do
          post :create, :agent => @attrs
          response.should redirect_to(new_user_session_url)
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved agent as @agent" do
          post :create, :agent => @invalid_attrs
          assigns(:agent).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :agent => @invalid_attrs
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end

  describe "PUT update" do
    before(:each) do
      @agent = FactoryGirl.create(:agent)
      @attrs = valid_attributes
      @invalid_attrs = FactoryGirl.attributes_for(:agent, :full_name => '')
    end

    describe "When logged in as Administrator" do
      login_fixture_admin

      describe "with valid params" do
        it "updates the requested agent" do
          put :update, :id => @agent.id, :agent => @attrs
        end

        it "assigns the requested agent as @agent" do
          put :update, :id => @agent.id, :agent => @attrs
          assigns(:agent).should eq(@agent)
        end
      end

      describe "with invalid params" do
        it "assigns the requested agent as @agent" do
          put :update, :id => @agent.id, :agent => @invalid_attrs
          response.should render_template("edit")
        end
      end
    end

    describe "When logged in as Librarian" do
      login_fixture_librarian

      describe "with valid params" do
        it "updates the requested agent" do
          put :update, :id => @agent.id, :agent => @attrs
        end

        it "assigns the requested agent as @agent" do
          put :update, :id => @agent.id, :agent => @attrs
          assigns(:agent).should eq(@agent)
          response.should redirect_to(@agent)
        end
      end

      describe "with invalid params" do
        it "assigns the agent as @agent" do
          put :update, :id => @agent, :agent => @invalid_attrs
          assigns(:agent).should_not be_valid
        end

        it "re-renders the 'edit' template" do
          put :update, :id => @agent, :agent => @invalid_attrs
          response.should render_template("edit")
        end
      end

      #it "should update other agent" do
      #  put :update, :id => users(:user2).agent.id, :agent => { :full_name => 'test' }
      #  response.should redirect_to agent_url(assigns(:agent))
      #end
    end

    describe "When logged in as User" do
      login_fixture_user

      describe "with valid params" do
        it "updates the requested agent" do
          put :update, :id => @agent.id, :agent => @attrs
        end

        it "assigns the requested agent as @agent" do
          put :update, :id => @agent.id, :agent => @attrs
          assigns(:agent).should eq(@agent)
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns the requested agent as @agent" do
          put :update, :id => @agent.id, :agent => @invalid_attrs
          response.should be_forbidden
        end
      end

      #it "should update myself" do
      #  put :update, :id => users(:user1).agent.id, :agent => { :full_name => 'test' }
      #  assigns(:agent).should be_valid
      #  response.should redirect_to agent_url(assigns(:agent))
      #end
  
      #it "should not update myself without name" do
      #  put :update, :id => users(:user1).agent.id, :agent => { :first_name => '', :last_name => '', :full_name => '' }
      #  assigns(:agent).should_not be_valid
      #  response.should be_success
      #end
  
      #it "should not update other agent" do
      #  put :update, :id => users(:user2).agent.id, :agent => { :full_name => 'test' }
      #  response.should be_forbidden
      #end
    end

    describe "When not logged in" do
      describe "with valid params" do
        it "updates the requested agent" do
          put :update, :id => @agent.id, :agent => @attrs
        end

        it "should be forbidden" do
          put :update, :id => @agent.id, :agent => @attrs
          response.should redirect_to(new_user_session_url)
        end
      end

      describe "with invalid params" do
        it "assigns the requested agent as @agent" do
          put :update, :id => @agent.id, :agent => @invalid_attrs
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end

  describe "DELETE destroy" do
    before(:each) do
      @agent = FactoryGirl.create(:agent)
    end

    describe "When logged in as Administrator" do
      login_fixture_admin

      it "destroys the requested agent" do
        delete :destroy, :id => @agent.id
      end

      it "redirects to the agents list" do
        delete :destroy, :id => @agent.id
        response.should redirect_to(agents_url)
      end

      #it "should not destroy librarian who has items checked out" do
      #  delete :destroy, :id => users(:librarian1).agent.id
      #  response.should be_forbidden
      #end

      #it "should destroy librarian who does not have items checked out" do
      #  delete :destroy, :id => users(:librarian2).agent.id
      #  response.should redirect_to agents_url
      #end
    end

    describe "When logged in as Librarian" do
      login_fixture_librarian

      it "destroys the requested agent" do
        delete :destroy, :id => @agent.id
      end

      it "redirects to the agents list" do
        delete :destroy, :id => @agent.id
        response.should redirect_to(agents_url)
      end

      #it "should not destroy librarian" do
      #  delete :destroy, :id => users(:librarian2).agent.id
      #  response.should be_forbidden
      #end
    end

    describe "When logged in as User" do
      login_fixture_user

      it "destroys the requested agent" do
        delete :destroy, :id => @agent.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @agent.id
        response.should be_forbidden
      end

      #it "should not destroy agent" do
      #  delete :destroy, :id => users(:user1).agent.id
      #  response.should be_forbidden
      #end
    end

    describe "When not logged in" do
      it "destroys the requested agent" do
        delete :destroy, :id => @agent.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @agent.id
        response.should redirect_to(new_user_session_url)
      end
    end
  end
end
