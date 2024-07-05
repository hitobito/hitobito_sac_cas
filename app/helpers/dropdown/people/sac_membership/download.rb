# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Dropdown
  class People::SacMembership::Download < ::Dropdown::Base
    attr_reader :person, :template

    delegate :t, to: :template

    def initialize(template, person)
      @template = template
      @person = person
      super(template, t("download"), :"file-download")
      init_items
    end

    private

    def init_items
      link = @template.membership_path(@person, format: :pdf)
      add_item(t("download_pdf"), link, method: :get)
    end

    def t(key)
      I18n.t("people.show_right_z_sac_cas.#{key}")
    end
  end
end
