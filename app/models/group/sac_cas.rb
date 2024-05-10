# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::SacCas < ::Group

  self.layer = true
  self.event_types = [Event::Course]

  children Group::Geschaeftsstelle,
           Group::Sektion,
           Group::ExterneKontakte,
           Group::Abonnenten,
           Group::Ehrenmitglieder

  mounted_attr :sac_newsletter_mailing_list_id, :integer
  mounted_attr :course_admin_email, :string

  validate :assert_sac_newsletter_mailing_list_id
  validate :assert_valid_course_admin_email

  private

  def assert_sac_newsletter_mailing_list_id
    return unless sac_newsletter_mailing_list_id
    ids = mailing_lists.pluck(:id)

    if ids.exclude?(sac_newsletter_mailing_list_id.to_i)
      errors.add(:sac_newsletter_mailing_list_id, :inclusion)
    end
  end

  def assert_valid_course_admin_email
    return unless course_admin_email.present?
    unless Truemail.valid?(course_admin_email.to_s)
      errors.add(:course_admin_email, :invalid)
    end
  end
end
