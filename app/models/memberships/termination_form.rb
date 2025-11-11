# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class Memberships::TerminationForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  attribute :terminate_on, :string
  attribute :termination_reason_id, :integer
  attribute :inform_mitglied_via_email, :boolean, default: true

  validates :terminate_on, inclusion: {in: :terminate_on_values}
  validates :termination_reason_id, presence: true

  attr_reader :terminate_on_values

  def initialize(terminate_on_values)
    @terminate_on_values = terminate_on_values
    super({})
  end

  def attributes_for_operation
    attributes.symbolize_keys
      .except(:terminate_on, :inform_mitglied_via_email)
      .merge(terminate_on: terminate_on_date_value)
  end

  def termination_reason_options
    TerminationReason.includes(:translations).all.map { |r| [r.text, r.id] }
  end

  def terminate_on_options
    terminate_on_values.map do |option|
      label = I18n.t("activemodel.attributes.wizards/steps/termination_choose_date.#{option}",
        year: Date.current.year)
      [option, label]
    end
  end

  def terminate_on_date_value
    (terminate_on == "now") ? Date.current.yesterday : Date.current.end_of_year
  end
end
