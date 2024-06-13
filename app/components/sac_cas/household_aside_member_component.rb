# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas::HouseholdAsideMemberComponent
  extend ActiveSupport::Concern

  prepended do
    def call
      members = entries.map do |member|
        content_tag :tr do
          content_tag(:td) do
            family_main_person_toggle_link(member)
          end +
          content_tag(:td) do
            content_tag(:strong) do
              person_entry(member)
            end +
            content_tag(:span, member_years(member))
          end
        end
      end
      safe_join(members)
    end

    def member_years(member)
      " (#{member.years})" if member.years
    end

    def family_main_person_toggle_link(member,
                                       title: I18n.t('people.roles_aside.set_main_group'))
      return ''.html_safe unless SacCas::Beitragskategorie::Calculator.new(member).adult?

      path = nil
      if member.sac_family_main_person?
        icon = helpers.icon(:star, filled: true)
        title = t('.main_person')
      elsif can_set_main_person_and_confirmed?(member)
        icon = helpers.icon(:star, filled: false)
        path = helpers.sac_family_main_person_path(member)
        title = t('.set_main_person')
      elsif cannot_set_main_person_but_confirmed?(member)
        icon = helpers.icon(:star, filled: false)
        title = t('.cannot_set_main_person')
      elsif !member.confirmed?
        icon = helpers.icon(:star, filled: false)
        title = t('.unverified_email')
      end
      attrs = { title: title, alt: title, class: 'text-primary' }

      if path
        helpers.link_to(icon, path,
                        attrs.merge(data: { method: :put, remote: true }))
      else
        content_tag(:span, icon, attrs)
      end
    end

    private

    def can_set_main_person_and_confirmed?(member)
      person.confirmed? &&
      can?(:set_sac_family_main_person, member)
    end

    def cannot_set_main_person_but_confirmed?(member)
      person.confirmed? &&
      !can?(:set_sac_family_main_person, member)
    end

    def show_toggle_link?(member)
      SacCas::Beitragskategorie::Calculator.new(member).adult?
    end
  end
end
