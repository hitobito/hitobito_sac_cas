# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module AssignsSacPhoneNumbers
  extend ActiveSupport::Concern

  private

  def assign_attributes
    super
    mark_phone_numbers_for_destroy(entry) if action_name == "update"
  end

  # Mark phone numbers for destruction if they have an empty number field.
  # This allows removing phone numbers by clearing the number field in the form.
  def mark_phone_numbers_for_destroy(contactable)
    PhoneNumber.predefined_labels.each do |label|
      phone_number_assoc = :"phone_number_#{label}"
      phone_number_params = model_params[:"#{phone_number_assoc}_attributes"]

      if phone_number_params && phone_number_params[:number].blank?
        contactable.send(phone_number_assoc)&.mark_for_destruction
      end
    end
  end
end
