# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


module SacCas::SelfRegistration::MainPerson
  extend ActiveSupport::Concern

  prepended do
    self.attrs = [
      :first_name, :last_name, :email, :gender, :birthday,
      :address, :zip_code, :town, :country,
      :additional_information,
      :phone_numbers_attributes,

      # Custom attrs
      :newsletter,
      :promocode,
      :privacy_policy_accepted,

      # Internal attrs
      :primary_group,
      :household_key
    ]

    self.required_attrs = [
      :first_name, :last_name, :email, :address, :zip_code, :town, :birthday
    ]

    attr_accessor(*attrs) # needs to be called for new attr accessors to be created
  end

  def person
    @person ||= Person.new(attributes.except(:newsletter, :promocode)).tap do |p|
      p.tag_list.add 'newsletter' if attributes[:newsletter]
      p.tag_list.add 'promocode' if attributes[:promocode]
    end
  end
end
