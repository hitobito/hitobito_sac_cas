# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SelfRegistration::InfosComponent < ApplicationComponent
  def additional_infos
    t(".additional_infos", link: build_link(:faqs)).html_safe
  end

  def document_links
    %w[statutes contribution_regulations data_protection].map do |key|
      build_link(key)
    end
  end

  private

  def build_link(key)
    title = t(".link_#{key}_title")
    target = t(".link_#{key}")
    link_to(title, target, target: :_blank, rel: :noopener)
  end

  def fetch(constant)
    constant.fetch(I18n.locale, :de)
  end
end
