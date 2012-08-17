class PatronImportFilesController < ApplicationController
  load_and_authorize_resource

  # GET /patron_import_files
  # GET /patron_import_files.json
  def index
    @patron_import_files = PatronImportFile.page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @patron_import_files }
    end
  end

  # GET /patron_import_files/1
  # GET /patron_import_files/1.json
  def show
    if @patron_import_file.patron_import.path
      unless Setting.uploaded_file.storage == :s3
        file = @patron_import_file.patron_import.path
      end
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @patron_import_file }
      format.download {
        if Setting.uploaded_file.storage == :s3
          redirect_to @patron_import_file.patron_import.expiring_url(10)
        else
          send_file file, :filename => @patron_import_file.patron_import_file_name, :type => 'application/octet-stream'
        end
      }
    end
  end

  # GET /patron_import_files/new
  # GET /patron_import_files/new.json
  def new
    @patron_import_file = PatronImportFile.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @patron_import_file }
    end
  end

  # GET /patron_import_files/1/edit
  def edit
  end

  # POST /patron_import_files
  # POST /patron_import_files.json
  def create
    @patron_import_file = PatronImportFile.new(params[:patron_import_file])
    @patron_import_file.user = current_user

    respond_to do |format|
      if @patron_import_file.save
        format.html { redirect_to @patron_import_file, :notice => t('controller.successfully_created', :model => t('activerecord.models.patron_import_file')) }
        format.json { render :json => @patron_import_file, :status => :created, :location => @patron_import_file }
      else
        format.html { render :action => "new" }
        format.json { render :json => @patron_import_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /patron_import_files/1
  # PUT /patron_import_files/1.json
  def update
    respond_to do |format|
      if @patron_import_file.update_attributes(params[:patron_import_file])
        format.html { redirect_to @patron_import_file, :notice => t('controller.successfully_updated', :model => t('activerecord.models.patron_import_file')) }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @patron_import_file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /patron_import_files/1
  # DELETE /patron_import_files/1.json
  def destroy
    @patron_import_file.destroy

    respond_to do |format|
      format.html { redirect_to(patron_import_files_url) }
      format.json { head :no_content }
    end
  end
end
