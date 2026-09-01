# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular::People
  class CornercardApplications < Export::Tabular::Base
    self.model_class = Person

    ATTRIBUTES = [
      :id,
      :last_name,
      :first_name,
      :gender,
      :birthday,
      :email,
      :mobile,
      :street,
      :housenumber,
      :postbox,
      :zip_code,
      :town,
      :country
    ].freeze

    self.row_class = CornercardApplicationsRow

    class_attribute :attributes
    self.attributes = ATTRIBUTES

    def initialize(uploads)
      scope = uploads.includes(person: :phone_number_mobile)
        .order("cornercard_uploads.created_at ASC")
      super(scope)
    end

    def attribute_label(attr)
      I18n.t("export/tabular/people/cornercard_applications.attributes.#{attr}")
    end

    def row_for(entry, format = nil)
      row_class.new(entry, format)
    end
  end
end
