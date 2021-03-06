class ProducesController < ApplicationController
  before_action :set_produce, only: [:show, :edit, :update, :destroy]
  after_action :verify_authorized
  before_action :get_agent, :get_manifestation
  before_action :prepare_options, :only => [:new, :edit]

  # GET /produces
  # GET /produces.json
  def index
    authorize Produce
    case
    when @agent
      @produces = @agent.produces.order('produces.position').page(params[:page])
    when @manifestation
      @produces = @manifestation.produces.order('produces.position').page(params[:page])
    else
      @produces = Produce.page(params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @produces }
    end
  #rescue
  #  respond_to do |format|
  #    format.html { render :action => "new" }
  #    format.json { render :json => @produce.errors, :status => :unprocessable_entity }
  #  end
  end

  # GET /produces/1
  # GET /produces/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @produce }
    end
  end

  # GET /produces/new
  def new
    if @agent and @manifestation.blank?
      redirect_to agent_manifestations_url(@agent)
      return
    elsif @manifestation and @agent.blank?
      redirect_to manifestation_agents_url(@manifestation)
      return
    else
      @produce = Produce.new
      authorize @produce
      @produce.manifestation = @manifestation
      @produce.agent = @agent
    end
  end

  # GET /produces/1/edit
  def edit
  end

  # POST /produces
  # POST /produces.json
  def create
    @produce = Produce.new(produce_params)
    authorize @produce

    respond_to do |format|
      if @produce.save
        format.html { redirect_to @produce, :notice => t('controller.successfully_created', :model => t('activerecord.models.produce')) }
        format.json { render :json => @produce, :status => :created, :location => @produce }
      else
        prepare_options
        format.html { render :action => "new" }
        format.json { render :json => @produce.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /produces/1
  # PUT /produces/1.json
  def update
    if @manifestation and params[:move]
      move_position(@produce, params[:move], false)
      redirect_to manifestation_produces_url(@manifestation)
      return
    end

    respond_to do |format|
      if @produce.update_attributes(produce_params)
        format.html { redirect_to @produce, :notice => t('controller.successfully_updated', :model => t('activerecord.models.produce')) }
        format.json { head :no_content }
      else
        prepare_options
        format.html { render :action => "edit" }
        format.json { render :json => @produce.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /produces/1
  # DELETE /produces/1.json
  def destroy
    @produce.destroy

    respond_to do |format|
      format.html {
        flash[:notice] = t('controller.successfully_destroyed', :model => t('activerecord.models.produce'))
        case
        when @agent
          redirect_to agent_manifestations_url(@agent)
        when @manifestation
          redirect_to manifestation_agents_url(@manifestation)
        else
          redirect_to produces_url
        end
      }
      format.json { head :no_content }
    end
  end

  private
  def set_produce
    @produce = Produce.find(params[:id])
    authorize @produce
  end

  def prepare_options
    @produce_types = ProduceType.all
  end

  def produce_params
    params.require(:produce).permit(
      :agent_id, :manifestation_id, :produce_type_id
    )
  end
end
