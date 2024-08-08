# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module Wizards::Steps::Signup
  class MainEmailField < Wizards::Step
    include ActiveModel::Dirty # required for ValidatedEmail
    include ValidatedEmail

    attribute :email, :string
    validates :email, presence: true

    validate :assert_valid_email_format

    private

    def assert_valid_email_format
      if email.present? && !Truemail.validate(email, with: :regex).result.success
        errors.add(:email, :invalid)
      end
    end
  end
end
