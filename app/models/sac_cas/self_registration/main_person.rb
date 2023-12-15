# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


module SacCas::SelfRegistration::MainPerson
  extend ActiveSupport::Concern

  prepended do
    self.attrs = [
      :first_name, :last_name, :nickname, :email,
      :newsletter,
      :promocode,
      :privacy_policy_accepted,
      :primary_group
    ]

    self.required_attrs = [
      :first_name, :last_name
    ]

    attr_accessor :step
  end

  def person
    @person ||= Person.new(attributes.except('newsletter', 'promocode').compact).tap do |p|
      p.tag_list.add 'newsletter' if attributes['newsletter']
      p.tag_list.add 'promocode' if attributes['promocode']
    end
  end
end
