# frozen_string_literal: true

#  Copyright (c) 2025, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class AccountCompletion < ActiveRecord::Base
  EXPIRES_AFTER = 3.months

  belongs_to :person

  attribute :email
  attribute :password

  validates_by_schema

  with_options on: :update do
    validates :email, :password, confirmation: true, presence: true
    validates :email_confirmation, :password_confirmation, presence: true
    validates :password, length: {in: Devise.password_length}, allow_blank: true
  end

  before_create :compute_token

  def self.generate(people, host:)
    CSV.generate do |csv|
      csv << %w[person_id account_completion_url]
      people.order(:id).find_each do |person|
        model = find_or_create_by!(person:)
        url = Rails.application.routes.url_helpers.account_completion_url(token: model.token, host:)
        csv << [person.id, url]
      end
    end
  end

  def expired? = created_at <= EXPIRES_AFTER.ago

  private

  def compute_token
    self.token = Devise.token_generator.generate(AccountCompletion, :token)[0]
  end
end
