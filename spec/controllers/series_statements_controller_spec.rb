require 'spec_helper'

describe SeriesStatementsController do
  fixtures :users

  def valid_attributes
    FactoryGirl.attributes_for(:series_statement)
  end

  describe "GET index", :solr => true do
    before do
      SeriesStatement.reindex
    end

    describe "When logged in as Administrator" do
      login_fixture_admin

      it "assigns all series_statements as @series_statements" do
        get :index
        assigns(:series_statements).should_not be_nil
      end
    end

    describe "When logged in as Librarian" do
      login_fixture_librarian

      it "assigns all series_statements as @series_statements" do
        get :index
        assigns(:series_statements).should_not be_nil
      end
    end

    describe "When logged in as User" do
      login_fixture_user

      it "assigns all series_statements as @series_statements" do
        get :index
        assigns(:series_statements).should_not be_nil
      end
    end

    describe "When not logged in" do
      it "assigns all series_statements as @series_statements" do
        get :index
        assigns(:series_statements).should_not be_nil
      end
    end
  end

  describe "GET show" do
    describe "When logged in as Administrator" do
      login_fixture_admin

      it "assigns the requested series_statement as @series_statement" do
        series_statement = FactoryGirl.create(:series_statement)
        get :show, :id => series_statement.id
        assigns(:series_statement).should eq(series_statement)
        response.should be_success
      end
    end

    describe "When logged in as Librarian" do
      login_fixture_librarian

      it "assigns the requested series_statement as @series_statement" do
        series_statement = FactoryGirl.create(:series_statement)
        get :show, :id => series_statement.id
        assigns(:series_statement).should eq(series_statement)
        response.should be_success
      end
    end

    describe "When logged in as User" do
      login_fixture_user

      it "assigns the requested series_statement as @series_statement" do
        series_statement = FactoryGirl.create(:series_statement)
        get :show, :id => series_statement.id
        assigns(:series_statement).should eq(series_statement)
        response.should be_success
      end
    end

    describe "When not logged in" do
      it "assigns the requested series_statement as @series_statement" do
        series_statement = FactoryGirl.create(:series_statement)
        get :show, :id => series_statement.id
        assigns(:series_statement).should eq(series_statement)
        response.should be_success
      end
    end
  end

  describe "GET new" do
    describe "When logged in as Administrator" do
      login_fixture_admin

      it "assigns the requested series_statement as @series_statement" do
        get :new
        assigns(:series_statement).should_not be_valid
      end
    end

    describe "When logged in as Librarian" do
      login_fixture_librarian

      it "assigns the requested series_statement as @series_statement" do
        get :new
        assigns(:series_statement).should_not be_valid
      end
    end

    describe "When logged in as User" do
      login_fixture_user

      it "should not assign the requested series_statement as @series_statement" do
        get :new
        assigns(:series_statement).should_not be_valid
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "should not assign the requested series_statement as @series_statement" do
        get :new
        assigns(:series_statement).should_not be_valid
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "GET edit" do
    describe "When logged in as Administrator" do
      login_fixture_admin

      it "assigns the requested series_statement as @series_statement" do
        series_statement = FactoryGirl.create(:series_statement)
        get :edit, :id => series_statement.id
        assigns(:series_statement).should eq(series_statement)
      end
    end

    describe "When logged in as Librarian" do
      login_fixture_librarian

      it "assigns the requested series_statement as @series_statement" do
        series_statement = FactoryGirl.create(:series_statement)
        get :edit, :id => series_statement.id
        assigns(:series_statement).should eq(series_statement)
      end
    end

    describe "When logged in as User" do
      login_fixture_user

      it "assigns the requested series_statement as @series_statement" do
        series_statement = FactoryGirl.create(:series_statement)
        get :edit, :id => series_statement.id
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "should not assign the requested series_statement as @series_statement" do
        series_statement = FactoryGirl.create(:series_statement)
        get :edit, :id => series_statement.id
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "POST create" do
    before(:each) do
      @attrs = valid_attributes
      @invalid_attrs = {:original_title => ''}
    end

    describe "When logged in as Administrator" do
      login_fixture_admin

      describe "with valid params" do
        it "assigns a newly created series_statement as @series_statement" do
          post :create, :series_statement => @attrs
          assigns(:series_statement).should be_valid
        end

        it "redirects to the created series_statement" do
          post :create, :series_statement => @attrs
          response.should redirect_to(series_statement_url(assigns(:series_statement)))
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved series_statement as @series_statement" do
          post :create, :series_statement => @invalid_attrs
          assigns(:series_statement).should_not be_valid
        end

        it "re-renders the 'new' template" do
          post :create, :series_statement => @invalid_attrs
          response.should render_template("new")
        end
      end
    end

    describe "When logged in as Librarian" do
      login_fixture_librarian

      describe "with valid params" do
        it "assigns a newly created series_statement as @series_statement" do
          post :create, :series_statement => @attrs
          assigns(:series_statement).should be_valid
        end

        it "redirects to the created series_statement" do
          post :create, :series_statement => @attrs
          response.should redirect_to(series_statement_url(assigns(:series_statement)))
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved series_statement as @series_statement" do
          post :create, :series_statement => @invalid_attrs
          assigns(:series_statement).should_not be_valid
        end

        it "re-renders the 'new' template" do
          post :create, :series_statement => @invalid_attrs
          response.should render_template("new")
        end
      end
    end

    describe "When logged in as User" do
      login_fixture_user

      describe "with valid params" do
        it "assigns a newly created series_statement as @series_statement" do
          post :create, :series_statement => @attrs
          assigns(:series_statement).should be_valid
        end

        it "should be forbidden" do
          post :create, :series_statement => @attrs
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved series_statement as @series_statement" do
          post :create, :series_statement => @invalid_attrs
          assigns(:series_statement).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :series_statement => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When not logged in" do
      describe "with valid params" do
        it "assigns a newly created series_statement as @series_statement" do
          post :create, :series_statement => @attrs
          assigns(:series_statement).should be_valid
        end

        it "should be forbidden" do
          post :create, :series_statement => @attrs
          response.should redirect_to(new_user_session_url)
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved series_statement as @series_statement" do
          post :create, :series_statement => @invalid_attrs
          assigns(:series_statement).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :series_statement => @invalid_attrs
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end

  describe "PUT update" do
    before(:each) do
      @series_statement = FactoryGirl.create(:series_statement)
      @attrs = valid_attributes
      @invalid_attrs = {:original_title => ''}
    end

    describe "When logged in as Administrator" do
      login_fixture_admin

      describe "with valid params" do
        it "updates the requested series_statement" do
          put :update, :id => @series_statement.id, :series_statement => @attrs
        end

        it "assigns the requested series_statement as @series_statement" do
          put :update, :id => @series_statement.id, :series_statement => @attrs
          assigns(:series_statement).should eq(@series_statement)
        end

        it "moves its position when specified" do
          put :update, :id => @series_statement.id, :move => 'lower'
          response.should redirect_to(series_statements_url)
        end
      end

      describe "with invalid params" do
        it "assigns the requested series_statement as @series_statement" do
          put :update, :id => @series_statement.id, :series_statement => @invalid_attrs
          response.should render_template("edit")
        end
      end
    end

    describe "When logged in as Librarian" do
      login_fixture_librarian

      describe "with valid params" do
        it "updates the requested series_statement" do
          put :update, :id => @series_statement.id, :series_statement => @attrs
        end

        it "assigns the requested series_statement as @series_statement" do
          put :update, :id => @series_statement.id, :series_statement => @attrs
          assigns(:series_statement).should eq(@series_statement)
          response.should redirect_to(@series_statement)
        end
      end

      describe "with invalid params" do
        it "assigns the series_statement as @series_statement" do
          put :update, :id => @series_statement, :series_statement => @invalid_attrs
          assigns(:series_statement).should_not be_valid
        end

        it "re-renders the 'edit' template" do
          put :update, :id => @series_statement, :series_statement => @invalid_attrs
          response.should render_template("edit")
        end
      end
    end

    describe "When logged in as User" do
      login_fixture_user

      describe "with valid params" do
        it "updates the requested series_statement" do
          put :update, :id => @series_statement.id, :series_statement => @attrs
        end

        it "assigns the requested series_statement as @series_statement" do
          put :update, :id => @series_statement.id, :series_statement => @attrs
          assigns(:series_statement).should eq(@series_statement)
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns the requested series_statement as @series_statement" do
          put :update, :id => @series_statement.id, :series_statement => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When not logged in" do
      describe "with valid params" do
        it "updates the requested series_statement" do
          put :update, :id => @series_statement.id, :series_statement => @attrs
        end

        it "should be forbidden" do
          put :update, :id => @series_statement.id, :series_statement => @attrs
          response.should redirect_to(new_user_session_url)
        end
      end

      describe "with invalid params" do
        it "assigns the requested series_statement as @series_statement" do
          put :update, :id => @series_statement.id, :series_statement => @invalid_attrs
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end

  describe "DELETE destroy" do
    before(:each) do
      @series_statement = FactoryGirl.create(:series_statement)
    end

    describe "When logged in as Administrator" do
      login_fixture_admin

      it "destroys the requested series_statement" do
        delete :destroy, :id => @series_statement.id
      end

      it "redirects to the series_statements list" do
        delete :destroy, :id => @series_statement.id
        response.should redirect_to(series_statements_url)
      end
    end

    describe "When logged in as Librarian" do
      login_fixture_librarian

      it "destroys the requested series_statement" do
        delete :destroy, :id => @series_statement.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @series_statement.id
        response.should redirect_to(series_statements_url)
      end
    end

    describe "When logged in as User" do
      login_fixture_user

      it "destroys the requested series_statement" do
        delete :destroy, :id => @series_statement.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @series_statement.id
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "destroys the requested series_statement" do
        delete :destroy, :id => @series_statement.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @series_statement.id
        response.should redirect_to(new_user_session_url)
      end
    end
  end
end
