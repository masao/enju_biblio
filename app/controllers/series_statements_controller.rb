# -*- encoding: utf-8 -*-
class SeriesStatementsController < ApplicationController
  load_and_authorize_resource
  before_filter :get_work, :get_manifestation, :get_parent_and_child, :except => [:create, :update, :destroy]
  cache_sweeper :page_sweeper, :only => [:create, :update, :destroy]
  after_filter :solr_commit, :only => [:create, :update, :destroy]
  if defined?(EnjuResourceMerge)
    before_filter :get_series_statement_merge_list, :except => [:create, :update, :destroy]
  end

  # GET /series_statements
  # GET /series_statements.json
  def index
    search = Sunspot.new_search(SeriesStatement)
    query = params[:query].to_s.strip
    page = params[:page] || 1
    unless query.blank?
      @query = query.dup
      query = query.gsub('　', ' ')
    end
    search.build do
      fulltext query if query.present?
      paginate :page => page.to_i, :per_page => SeriesStatement.default_per_page
      order_by :position, :asc
    end
    #work = @work
    manifestation = @manifestation
    parent = @parent
    child = @child
    series_statement_merge_list = @series_statement_merge_list
    unless params[:mode] == 'add'
      search.build do
      #  with(:work_id).equal_to work.id if work
        with(:parent_ids).equal_to parent.id if parent
        with(:child_ids).equal_to child.id if child
        with(:manifestation_ids).equal_to manifestation.id if manifestation
        with(:series_statement_merge_list_ids).equal_to series_statement_merge_list.id if series_statement_merge_list
      end
    else
      search.build do
        without(:parent_ids, parent.id) if parent
      end
    end
    page = params[:page] || 1
    search.query.paginate(page.to_i, SeriesStatement.default_per_page)
    @series_statements = search.execute!.results

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @series_statements }
    end
  end

  # GET /series_statements/1
  # GET /series_statements/1.json
  def show
    #@manifestations = @series_statement.manifestations.order('date_of_publication DESC').page(params[:manifestation_page]).per_page(Manifestation.per_page)
    #store_location

    respond_to do |format|
      format.html { # show.html.erb
        redirect_to series_statement_manifestations_url(@series_statement)
      }
      format.json { render :json => @series_statement }
      #format.js
      format.mobile {
        redirect_to series_statement_manifestations_url(@series_statement)
      }
    end
  end

  # GET /series_statements/new
  # GET /series_statements/new.json
  def new
    @series_statement = SeriesStatement.new
    @series_statement.parent = @parent_series_statement if @parent_series_statement

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @series_statement }
    end
  end

  # GET /series_statements/1/edit
  def edit
    @series_statement.work = @work if @work
    @series_statement.parent = @parent_series_statement if @parent_series_statement
  end

  # POST /series_statements
  # POST /series_statements.json
  def create
    @series_statement = SeriesStatement.new(params[:series_statement])
    manifestation = Manifestation.find(@series_statement.manifestation_id) rescue nil

    respond_to do |format|
      if @series_statement.save
        @series_statement.manifestations << manifestation if manifestation
        format.html { redirect_to @series_statement, :notice => t('controller.successfully_created', :model => t('activerecord.models.series_statement')) }
        format.json { render :json => @series_statement, :status => :created, :location => @series_statement }
      else
        format.html { render :action => "new" }
        format.json { render :json => @series_statement.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /series_statements/1
  # PUT /series_statements/1.json
  def update
    if params[:move]
      move_position(@series_statement, params[:move])
      return
    end

    respond_to do |format|
      if @series_statement.update_attributes(params[:series_statement])
        format.html { redirect_to @series_statement, :notice => t('controller.successfully_updated', :model => t('activerecord.models.series_statement')) }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @series_statement.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /series_statements/1
  # DELETE /series_statements/1.json
  def destroy
    @series_statement.destroy

    respond_to do |format|
      format.html { redirect_to series_statements_url }
      format.json { head :no_content }
    end
  end

  private
  def get_parent_and_child
    @parent = SeriesStatement.find(params[:parent_id]) if params[:parent_id]
    @child = SeriesStatement.find(params[:child_id]) if params[:child_id]
  end
end
