require 'spec_helper'
require 'sunspot/rails/spec_helper'

describe ImportRequestsController do
  fixtures :all
  disconnect_sunspot

  describe "GET index" do
    describe "When logged in as Administrator" do
      login_admin

      it "assigns all import_requests as @import_requests" do
        get :index
        assigns(:import_requests).should eq(ImportRequest.all)
      end
    end

    describe "When logged in as Librarian" do
      login_librarian

      it "assigns all import_requests as @import_requests" do
        get :index
        assigns(:import_requests).should eq(ImportRequest.all)
      end
    end

    describe "When logged in as User" do
      login_user

      it "assigns empty as @import_requests" do
        get :index
        assigns(:import_requests).should be_empty
      end
    end

    describe "When not logged in" do
      it "assigns empty as @import_requests" do
        get :index
        assigns(:import_requests).should be_empty
      end
    end
  end

  describe "GET show" do
    describe "When logged in as Administrator" do
      login_admin

      it "assigns the requested import_request as @import_request" do
        import_request = import_requests(:one)
        get :show, :id => import_request.id
        assigns(:import_request).should eq(import_request)
      end
    end

    describe "When logged in as Librarian" do
      login_librarian

      it "assigns the requested import_request as @import_request" do
        import_request = import_requests(:one)
        get :show, :id => import_request.id
        assigns(:import_request).should eq(import_request)
      end
    end

    describe "When logged in as User" do
      login_user

      it "assigns the requested import_request as @import_request" do
        import_request = import_requests(:one)
        get :show, :id => import_request.id
        assigns(:import_request).should eq(import_request)
      end
    end

    describe "When not logged in" do
      it "assigns the requested import_request as @import_request" do
        import_request = import_requests(:one)
        get :show, :id => import_request.id
        assigns(:import_request).should eq(import_request)
      end
    end
  end

  describe "GET new" do
    describe "When logged in as Administrator" do
      login_admin

      it "assigns the requested import_request as @import_request" do
        get :new
        assigns(:import_request).should_not be_valid
      end
    end

    describe "When logged in as Librarian" do
      login_librarian

      it "assigns the requested import_request as @import_request" do
        get :new
        assigns(:import_request).should_not be_valid
      end
    end

    describe "When logged in as User" do
      login_user

      it "should not assign the requested import_request as @import_request" do
        get :new
        assigns(:import_request).should_not be_valid
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "should not assign the requested import_request as @import_request" do
        get :new
        assigns(:import_request).should_not be_valid
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "GET edit" do
    describe "When logged in as Administrator" do
      login_admin

      it "assigns the requested import_request as @import_request" do
        import_request = FactoryGirl.create(:import_request, :isbn => '9784797350999')
        get :edit, :id => import_request.id
        assigns(:import_request).should eq(import_request)
      end
    end

    describe "When logged in as Librarian" do
      login_librarian

      it "assigns the requested import_request as @import_request" do
        import_request = FactoryGirl.create(:import_request, :isbn => '9784797350999')
        get :edit, :id => import_request.id
        assigns(:import_request).should eq(import_request)
      end
    end

    describe "When logged in as User" do
      login_user

      it "assigns the requested import_request as @import_request" do
        import_request = FactoryGirl.create(:import_request, :isbn => '9784797350999')
        get :edit, :id => import_request.id
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "should not assign the requested import_request as @import_request" do
        import_request = FactoryGirl.create(:import_request, :isbn => '9784797350999')
        get :edit, :id => import_request.id
        response.should redirect_to(new_user_session_url)
      end
    end
  end

  describe "POST create" do
    before(:each) do
      @attrs = {:isbn => '9784873114422'}
      @invalid_attrs = {:isbn => 'invalid'}
    end

    describe "When logged in as Administrator" do
      login_admin

      describe "with valid params", :vcr => true do
        it "assigns a newly created import_request as @import_request" do
          post :create, :import_request => @attrs
          assigns(:import_request).manifestation.save! #should be_valid
        end

        it "redirects to the created import_request" do
          post :create, :import_request => @attrs
          response.should redirect_to manifestation_url(assigns(:import_request).manifestation)
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved import_request as @import_request" do
          post :create, :import_request => @invalid_attrs
          assigns(:import_request).should_not be_valid
        end

        it "re-renders the 'new' template" do
          post :create, :import_request => @invalid_attrs
          response.should render_template("new")
        end
      end

      describe "with isbn which is already imported" do
        it "assigns a newly created import_request as @import_request" do
          post :create, :import_request => {:isbn => manifestations(:manifestation_00001).identifier_contents(:isbn).first}
          assigns(:import_request).should be_valid
        end

        it "redirects to the created import_request", :vcr => true do
          post :create, :import_request => @attrs
          response.should redirect_to manifestation_url(assigns(:import_request).manifestation)
        end
      end
    end

    describe "When logged in as Librarian" do
      login_librarian

      describe "with valid params", :vcr => true do
        it "assigns a newly created import_request as @import_request" do
          post :create, :import_request => @attrs
          assigns(:import_request).should be_valid
        end

        it "redirects to the created import_request" do
          post :create, :import_request => @attrs
          response.should redirect_to manifestation_url(assigns(:import_request).manifestation)
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved import_request as @import_request" do
          post :create, :import_request => @invalid_attrs
          assigns(:import_request).should_not be_valid
        end

        it "re-renders the 'new' template" do
          post :create, :import_request => @invalid_attrs
          response.should render_template("new")
        end
      end
    end

    describe "When logged in as User" do
      login_user

      describe "with valid params" do
        it "assigns a newly created import_request as @import_request" do
          post :create, :import_request => @attrs
          assigns(:import_request).should be_valid
        end

        it "should be forbidden" do
          post :create, :import_request => @attrs
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved import_request as @import_request" do
          post :create, :import_request => @invalid_attrs
          assigns(:import_request).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :import_request => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When not logged in" do
      describe "with valid params" do
        it "assigns a newly created import_request as @import_request" do
          post :create, :import_request => @attrs
          assigns(:import_request).should be_valid
        end

        it "should be forbidden" do
          post :create, :import_request => @attrs
          response.should redirect_to(new_user_session_url)
        end
      end

      describe "with invalid params" do
        it "assigns a newly created but unsaved import_request as @import_request" do
          post :create, :import_request => @invalid_attrs
          assigns(:import_request).should_not be_valid
        end

        it "should be forbidden" do
          post :create, :import_request => @invalid_attrs
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end

  describe "PUT update" do
    before(:each) do
      @import_request = import_requests(:one)
      @attrs = {:isbn => '9784797350999'}
      @invalid_attrs = {:isbn => 'invalid'}
    end

    describe "When logged in as Administrator" do
      login_admin

      describe "with valid params" do
        it "updates the requested import_request" do
          put :update, :id => @import_request.id, :import_request => @attrs
        end

        it "assigns the requested import_request as @import_request" do
          put :update, :id => @import_request.id, :import_request => @attrs
          assigns(:import_request).should eq(@import_request)
        end
      end

      describe "with invalid params" do
        it "assigns the requested import_request as @import_request" do
          put :update, :id => @import_request.id, :import_request => @invalid_attrs
          response.should render_template("edit")
        end
      end
    end

    describe "When logged in as Librarian" do
      login_librarian

      describe "with valid params" do
        it "updates the requested import_request" do
          put :update, :id => @import_request.id, :import_request => @attrs
        end

        it "assigns the requested import_request as @import_request" do
          put :update, :id => @import_request.id, :import_request => @attrs
          assigns(:import_request).should eq(@import_request)
          response.should redirect_to(@import_request)
        end
      end

      describe "with invalid params" do
        it "assigns the import_request as @import_request" do
          put :update, :id => @import_request, :import_request => @invalid_attrs
          assigns(:import_request).should_not be_valid
        end

        it "re-renders the 'edit' template" do
          put :update, :id => @import_request, :import_request => @invalid_attrs
          response.should render_template("edit")
        end
      end
    end

    describe "When logged in as User" do
      login_user

      describe "with valid params" do
        it "updates the requested import_request" do
          put :update, :id => @import_request.id, :import_request => @attrs
        end

        it "assigns the requested import_request as @import_request" do
          put :update, :id => @import_request.id, :import_request => @attrs
          assigns(:import_request).should eq(@import_request)
          response.should be_forbidden
        end
      end

      describe "with invalid params" do
        it "assigns the requested import_request as @import_request" do
          put :update, :id => @import_request.id, :import_request => @invalid_attrs
          response.should be_forbidden
        end
      end
    end

    describe "When not logged in" do
      describe "with valid params" do
        it "updates the requested import_request" do
          put :update, :id => @import_request.id, :import_request => @attrs
        end

        it "should be redirected to new session url" do
          put :update, :id => @import_request.id, :import_request => @attrs
          response.should redirect_to(new_user_session_url)
        end
      end

      describe "with invalid params" do
        it "assigns the requested import_request as @import_request" do
          put :update, :id => @import_request.id, :import_request => @invalid_attrs
          response.should redirect_to(new_user_session_url)
        end
      end
    end
  end

  describe "DELETE destroy" do
    before(:each) do
      @import_request = import_requests(:one)
    end

    describe "When logged in as Administrator" do
      login_admin

      it "destroys the requested import_request" do
        delete :destroy, :id => @import_request.id
      end

      it "redirects to the import_requests list" do
        delete :destroy, :id => @import_request.id
        response.should redirect_to(import_requests_url)
      end
    end

    describe "When logged in as Librarian" do
      login_librarian

      it "destroys the requested import_request" do
        delete :destroy, :id => @import_request.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @import_request.id
        response.should redirect_to(import_requests_url)
      end
    end

    describe "When logged in as User" do
      login_user

      it "destroys the requested import_request" do
        delete :destroy, :id => @import_request.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @import_request.id
        response.should be_forbidden
      end
    end

    describe "When not logged in" do
      it "destroys the requested import_request" do
        delete :destroy, :id => @import_request.id
      end

      it "should be forbidden" do
        delete :destroy, :id => @import_request.id
        response.should redirect_to(new_user_session_url)
      end
    end
  end
end
