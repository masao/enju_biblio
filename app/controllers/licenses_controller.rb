class LicensesController < InheritedResources::Base
  respond_to :html, :json
  load_and_authorize_resource

  def update
    @license = License.find(params[:id])
    if params[:move]
      move_position(@license, params[:move])
      return
    end
    update!
  end

  def index
    @licenses = @licenses.page(params[:page])
  end
end
