# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include EnjuLeaf::EnjuLeafHelper
  include EnjuBiblio::BiblioHelper if defined?(EnjuBiblio)
  if defined?(EnjuManifestationViewer)
    include EnjuManifestationViewer::BookJacketHelper
    include EnjuManifestationViewer::ManifestationViewerHelper
  end
end
