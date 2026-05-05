# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacCas
  module PaperTrail
    module VersionAssociationChangePresenter
      extend ActiveSupport::Concern

      private

      def translate_association_change(label, changeset)
        return translate_approval_change if item_type == ::Event::Approval.sti_name

        super
      end

      def translate_approval_change
        I18n.t(
          approval_change_translation_key,
          freigabe_komitee: reifyed_item.freigabe_komitee&.name,
          approval_kind: reifyed_item.approval_kind
        )
      end

      def approval_change_translation_key
        key = if reifyed_item.freigabe_komitee.nil?
          "self_approval"
        elsif reifyed_item.approved?
          "approved"
        else
          "rejected"
        end

        "version.association_change.event/approval.#{key}"
      end
    end
  end
end
