module EnjuBiblio
  module BiblioHelper
    def form_icon(carrier_type)
      case carrier_type.name
      when 'print'
        image_tag('icons/book.png', :size => '16x16', :alt => carrier_type.display_name.localize)
      when 'CD'
        image_tag('icons/cd.png', :size => '16x16', :alt => carrier_type.display_name.localize)
      when 'DVD'
        image_tag('icons/dvd.png', :size => '16x16', :alt => carrier_type.display_name.localize)
      when 'file'
        image_tag('icons/monitor.png', :size => '16x16', :alt => carrier_type.display_name.localize)
      else
        image_tag('icons/help.png', :size => '16x16', :alt => t('page.unknown'))
      end
    rescue NoMethodError
      image_tag('icons/help.png', :size => '16x16', :alt => t('page.unknown'))
    end

    def content_type_icon(content_type)
      case content_type.name
      when 'text'
        image_tag('icons/page_white_text.png', :size => '16x16', :alt => content_type.display_name.localize)
      when 'picture'
        image_tag('icons/picture.png', :size => '16x16', :alt => content_type.display_name.localize)
      when 'sound'
        image_tag('icons/sound.png', :size => '16x16', :alt => content_type.display_name.localize)
      when 'video'
        image_tag('icons/film.png', :size => '16x16', :alt => content_type.display_name.localize)
      else
        image_tag('icons/help.png', :size => '16x16', :alt => t('page.unknown'))
      end
    rescue NoMethodError
      image_tag('icons/help.png', :size => '16x16', :alt => t('page.unknown'))
    end

    def agent_type_icon(agent_type)
      case agent_type
      when 'Person'
        image_tag('icons/user.png', :size => '16x16', :alt => 'Person')
      when 'CorporateBody'
        image_tag('icons/group.png', :size => '16x16', :alt => 'CorporateBody')
      else
        image_tag('icons/help.png', :size => '16x16', :alt => t('page.unknown'))
      end
    end

    def agents_list(agents = [], options = {})
      return nil if agents.blank?
      agents_list = []
      if options[:nolink]
        agents_list = agents.map{|agent| agent.full_name}
      else
        agents_list = agents.map{|agent| link_to(agent.full_name, manifestations_path(:query => "\"#{agent.full_name}\""), options)}
      end
      agents_list.join(" ").html_safe
    end
  end
end
