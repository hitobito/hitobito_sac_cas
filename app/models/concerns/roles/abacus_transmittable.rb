# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Roles::AbacusTransmittable
  extend ActiveSupport::Concern

  included do
    after_create_commit :transmit_data_to_abacus
  end

  private

  def transmit_data_to_abacus
    Invoices::Abacus::TransmitPersonJob.new(person).enqueue! if
      person.abacus_subject_key.blank? &&
        person.data_quality != "error"
  end
end
