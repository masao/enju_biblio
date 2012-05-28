class ProduceTypesController < InheritedResources::Base
  respond_to :html, :json
  load_and_authorize_resource

  def update
    @produce_type = ProduceType.find(params[:id])
    if params[:move]
      move_position(@produce_type, params[:move])
      return
    end
    update!
  end
end
