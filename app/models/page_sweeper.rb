class PageSweeper < ActionController::Caching::Sweeper
  include ExpireEditableFragment
  observe Create, Realize, Produce, Own, Exemplify,
    SeriesStatement, PictureFile

  def after_save(record)
    case record.class.to_s.to_sym
    when :Create
      expire_editable_fragment(record.agent)
      expire_editable_fragment(record.work)
    when :Realize
      expire_editable_fragment(record.agent)
      expire_editable_fragment(record.expression)
    when :Produce
      expire_editable_fragment(record.agent)
      expire_editable_fragment(record.manifestation)
    when :Own
      expire_editable_fragment(record.agent)
      expire_editable_fragment(record.item)
      expire_editable_fragment(record.item.manifestation)
    when :Exemplify
      expire_editable_fragment(record.manifestation)
      expire_editable_fragment(record.item)
    when :SeriesStatement
      expire_editable_fragment(record.manifestation)
    when :PictureFile
      if record.picture_attachable_type?
        expire_editable_fragment(record.picture_attachable)
      end
    end
  end

  def after_destroy(record)
    after_save(record)
  end
end
