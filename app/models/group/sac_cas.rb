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

  class << self
    def mount_mailing_lists(*keys)
      @@mounted_mailing_list_attrs = keys.map { |key| :"sac_#{key}_mailing_list_id" }
      @@mounted_mailing_list_attrs.each { |attr| mounted_attr attr, :integer }

      validate :assert_mounted_mailing_list_attrs
    end
  end

  mounted_attr :course_admin_email, :string
  mount_mailing_lists :newsletter, :inside, :tourenportal, :magazin, :huettenportal

  validate :assert_valid_course_admin_email

  has_many :sac_membership_configs, dependent: :destroy

  private

  def assert_mounted_mailing_list_attrs
    mapped_lists = @@mounted_mailing_list_attrs.map { |key| [key, send(key)] }.to_h.compact
    mapped_lists.each do |key, id|
      errors.add(key, :inclusion) unless mailing_lists.where(id: id).exists?
    end
  end

  def assert_valid_course_admin_email
    return unless course_admin_email.present?
    unless Truemail.valid?(course_admin_email.to_s)
      errors.add(:course_admin_email, :invalid)
    end
  end
end
