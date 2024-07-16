# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class ExternalInvoice < ActiveRecord::Base
  STATES = %w[draft open payed cancelled error]

  include I18nEnums

  belongs_to :person
  belongs_to :link, polymorphic: true, optional: true
  has_many :hitobito_log_entries, as: :subject, dependent: :nullify

  i18n_enum :state, STATES, scopes: true, queries: true

  validates_by_schema
  validates :state, inclusion: {in: STATES}

  def type_key
    self.class.name.demodulize.underscore
  end
end
