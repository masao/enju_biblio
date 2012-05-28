class ManifestationRelationshipTypesController < InheritedResources::Base
  respond_to :html, :json
  load_and_authorize_resource

  def update
    @manifestation_relationship_type = ManifestationRelationshipType.find(params[:id])
    if params[:move]
      move_position(@manifestation_relationship_type, params[:move])
      return
    end
    update!
  end
end
