# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SelfRegistrationAbo < SelfRegistration
  self.partials = [:abo_issue, :abo_main_person]

  attr_accessor :issues_from_date
  attr_reader :errors

  def initialize(group:, params: )
    super(group: group, params: params)

    @errors = ActiveModel::Errors.new(self)
    @issues_from_date = params.dig(:self_registration_abo, :issues_from_date)
  end

  def main_person
    @main_person ||= build_person(@main_person_attributes, MainPerson)
  end

  private

  def abo_issue_valid?
    issues_from_date.present?.tap do |present|
      errors.add(:issues_from_date, :blank) unless present
    end
  end

  def abo_main_person_valid?
    main_person.valid?
  end
end
