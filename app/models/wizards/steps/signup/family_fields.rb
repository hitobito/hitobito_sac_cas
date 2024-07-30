# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Steps::Signup
  class FamilyFields < Wizards::Step
    MAX_ADULT_COUNT = SacCas::Role::MitgliedFamilyValidations::MAXIMUM_ADULT_FAMILY_MEMBERS_COUNT

    validate :assert_adult_count

    attr_reader :emails

    def build_member(attrs = {})
      FamilyFields::Member.new(self, attrs)
    end

    def valid?
      super && members_valid?
    end

    def members_attributes=(attributes)
      @members = attributes.map do |index, attrs|
        next if attrs[:_destroy].present?

        build_member(attrs)
      end.compact
    end

    def members
      @members || []
    end

    private

    def assert_adult_count
      if members.count(&:adult?) >= MAX_ADULT_COUNT
        message = I18n.t("activerecord.errors.messages.too_many_adults_in_family", max_adults: MAX_ADULT_COUNT)
        errors.add(:base, message)
      end
    end

    def members_valid?
      @emails = [wizard.email]
      members.each(&:valid?)
      members.none? { |m| m.errors.any? }
    end
  end
end
