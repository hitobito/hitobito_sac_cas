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
        return item_label if item_type == ::Event::Approval.sti_name

        super
      end
    end
  end
end
