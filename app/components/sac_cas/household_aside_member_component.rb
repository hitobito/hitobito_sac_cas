# frozen_string_literal: true

#  Copyright (c) 2012-2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas
  module HouseholdAsideMemberComponent
    extend ActiveSupport::Concern

    prepended do
      delegate :icon, :link_to, :sac_family_main_person_path, to: :helpers

      def call
        safe_join(entry_rows)
      end

      private

      def entry_rows
        entries.map { |member| member_row(member) }
      end

      def member_row(member)
        content_tag :tr do
          safe_join(member_columns(member))
        end
      end

      def member_columns(member)
        [
          content_tag(:td, family_main_person_toggle_link(member)),
          content_tag(:td, person_entry(member) + member_years(member))
        ].compact
      end

      def family_main_person_toggle_link(member)
        return '' unless show_toggle_link?(member)

        icon_html(member)
      end

      def icon_html(member)
        icon, title = icon_details_based_on_status(member)
        attrs = { title: title, alt: title, class: 'text-primary' }
        if !member.sac_family_main_person? && can_set_main_person_and_confirmed?(member)
          link_to(icon, icon_path(member),
                  attrs.merge(data: { method: :put, remote: true }))
        else
          content_tag(:span, icon, attrs)
        end
      end

      def icon_details_based_on_status(member)
        if member.sac_family_main_person?
          [icon(:star, filled: true), t('.main_person')]
        elsif can_set_main_person_and_confirmed?(member)
          [icon(:star, filled: false), t('.set_main_person')]
        elsif cannot_set_main_person_but_confirmed?(member)
          [icon(:star, filled: false), t('.cannot_set_main_person')]
        else
          [icon(:star, filled: false), t('.unverified_email')]
        end
      end

      def member_years(member)
        content_tag(:span, " (#{member.years})") if member.years
      end

      def show_toggle_link?(member)
        SacCas::Beitragskategorie::Calculator.new(member).adult? && member.sac_family_member?
      end

      def can_set_main_person_and_confirmed?(member)
        member.confirmed? && can?(:set_sac_family_main_person, member)
      end

      def cannot_set_main_person_but_confirmed?(member)
        member.confirmed? && !can?(:set_sac_family_main_person, member)
      end

      def icon_path(member)
        sac_family_main_person_path(member)
      end
    end
  end
end
