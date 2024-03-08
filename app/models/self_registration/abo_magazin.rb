# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SelfRegistration
  class AboMagazin < Base
    self.partials += [:abo_issue]
    self.shared_partial = :abo_infos
    self.main_person_class = SelfRegistration::Abo::MainPerson

    attr_accessor :issues_from

    def initialize(group:, params: )
      super(group: group, params: params)

      @today = Date.today
      @issues_from = params.dig(:self_registration_abo_magazin, :issues_from)
    end

    def dummy_costs
      [
        OpenStruct.new(amount: 60, country: :switzerland),
        OpenStruct.new(amount: 76, country: :international),
      ]
    end

    def main_person
      super.tap do |p|
        p.register_on_date = issues_from_date
      end
    end

    def errors
      @errors ||= ActiveModel::Errors.new(self)
    end

    private

    def abo_issue_valid?
      issues_from_valid?.tap do |valid|
        errors.add(:issues_from, :on_or_after, restriction: I18n.l(@today)) unless valid
      end
    end

    def issues_from_valid?
      issues_from_date.blank? || @today <= issues_from_date
    end

    def issues_from_date
      Date.parse(issues_from.to_s) rescue nil
    end
  end
end
