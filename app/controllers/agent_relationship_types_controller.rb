class AgentRelationshipTypesController < InheritedResources::Base
  respond_to :html, :json
  has_scope :page, :default => 1
  load_and_authorize_resource except: :create
  authorize_resource only: :create

  def index
    @agent_relationship_types = AgentRelationshipType.page(params[:page])
  end

  def update
    @agent_relationship_type = AgentRelationshipType.find(params[:id])
    if params[:move]
      move_position(@agent_relationship_type, params[:move])
      return
    end
    update!
  end

  private
  def permitted_params
    params.permit(
      :agent_relationship_type => [:name, :display_name, :note]
    )
  end
end
