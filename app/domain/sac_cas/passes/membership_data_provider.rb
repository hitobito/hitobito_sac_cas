# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Passes
  class MembershipDataProvider < ::Passes::WalletDataProvider
    def member_number
      pass.person.membership_number
    end

    def extra_google_text_modules # rubocop:disable Metrics/MethodLength
      modules = [
        {
          header: I18n.t("passes.sac_membership.section"),
          body: stammsektion_name
        }
      ]
      if zusatzsektion_names.any?
        modules << {
          header: I18n.t("passes.sac_membership.additional_sections"),
          body: zusatzsektion_names.join(", ")
        }
      end
      if pass.person.sac_tour_guide?
        modules << {
          header: I18n.t("passes.sac_membership.tour_guide"),
          body: I18n.t("passes.sac_membership.tour_guide_active")
        }
      end
      modules
    end

    def extra_apple_fields # rubocop:disable Metrics/MethodLength
      fields = {
        secondaryFields: [
          {key: "section", label: I18n.t("passes.sac_membership.section"),
           value: stammsektion_name}
        ]
      }
      if zusatzsektion_names.any?
        fields[:auxiliaryFields] = [
          {
            key: "additional_sections",
            label: I18n.t("passes.sac_membership.additional_sections"),
            value: zusatzsektion_names.join(", ")
          }
        ]
      end
      if pass.person.sac_tour_guide?
        fields[:backFields] ||= []
        fields[:backFields] << {
          key: "tour_guide",
          label: I18n.t("passes.sac_membership.tour_guide"),
          value: I18n.t("passes.sac_membership.tour_guide_active")
        }
      end
      fields
    end

    private

    def stammsektion_name
      pass.person.primary_group&.layer_group&.name
    end

    def zusatzsektion_names
      pass.person.roles
        .where(type: Group::SektionsMitglieder::MitgliedZusatzsektion.sti_name)
        .map { |r| r.group.layer_group.to_s }
    end
  end
end
