# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::SacCas < ::Group

  self.layer = true
  self.event_types = [Event::Course]

  children Group::Geschaeftsstelle,
           Group::Geschaeftsleitung,
           Group::Zentralvorstand,
           Group::Kommission,
           Group::Sektion,
           Group::ExterneKontakte,
           Group::Abonnenten,
           Group::Ehrenmitglieder

  mounted_attr :course_admin_email, :string
  mounted_attr :sac_newsletter_mailing_list_id, :integer
  mounted_attr :sac_magazine_mailing_list_id, :integer

  validate :assert_valid_course_admin_email
  validate :assert_mounted_mailing_list_attrs

  has_many :sac_membership_configs, dependent: :destroy

  private

  def assert_mounted_mailing_list_attrs
    unless mailing_lists.where(id: sac_newsletter_mailing_list_id).exists?
      errors.add(:sac_newsletter_mailing_list_id, :inclusion)
    end
    unless sac_magazine_mailing_list_id.nil? ||
      mailing_lists.where(id: sac_magazine_mailing_list_id).exists?
      errors.add(:sac_magazine_mailing_list_id, :inclusion)
    end
  end

  def assert_valid_course_admin_email
    return unless course_admin_email.present?
    unless Truemail.valid?(course_admin_email.to_s)
      errors.add(:course_admin_email, :invalid)
    end
  end
end
