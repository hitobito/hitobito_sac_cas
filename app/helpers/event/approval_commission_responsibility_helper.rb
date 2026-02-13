# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Event::ApprovalCommissionResponsibilityHelper
  def render_commission_select(f, entries, subito:, freigabe_komitees:)
    entry = entries.find { _1.subito == subito }

    f.fields_for :event_approval_commission_responsibilities, entry do |ff|
      capture do
        concat ff.hidden_field :id
        concat ff.hidden_field :target_group_id
        concat ff.hidden_field :discipline_id
        concat ff.hidden_field :subito
        concat ff.select :freigabe_komitee_id,
          freigabe_komitees.map { [_1.to_s, _1.id] },
          {prompt: true},
          {class: "form-select form-select-sm"}
      end
    end
  end
end
