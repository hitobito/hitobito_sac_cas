# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::Sheet::Person
  extend ActiveSupport::Concern

  prepended do
    tabs.insert(1, Sheet::Tab.new(
      "people.tabs.sac_remarks",
      :group_person_sac_remarks_path,
      if: ->(view, _group, person) { view.can?(:show_remarks, person) }
    ))

    # Insert external invoices tab (for example abacus bills)
    tabs.insert(3, Sheet::Tab.new(
      "people.tabs.external_invoices",
      :external_invoices_group_person_path,
      if: ->(view, group, person) do
        return false unless person.roles.map(&:group_id).include?(group.id)

        view.can?(:index_external_invoices, person)
      end
    ))

    # Remove regular invoices tab because we don't use it
    tabs.delete_if { |tab| tab.label_key == "people.tabs.invoices" }
  end
end
