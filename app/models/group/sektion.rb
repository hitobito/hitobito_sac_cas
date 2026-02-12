# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::Sektion < Group
  include Groups::WithNeuanmeldung

  self.layer = true
  self.event_types = [Event, Event::Tour, Event::Course]

  children Group::SektionsFunktionaere,
    Group::SektionsMitglieder,
    Group::SektionsNeuanmeldungenSektion,
    Group::SektionsNeuanmeldungenNv,
    Group::Ortsgruppe

  self.default_children = [
    Group::SektionsFunktionaere,
    Group::SektionsMitglieder,
    Group::SektionsNeuanmeldungenNv
  ]

  mounted_attr :foundation_year, :integer
  validates :foundation_year,
    numericality:
    {greater_or_equal_to: 1863, smaller_than: Time.zone.now.year + 2}
  mounted_attr :section_canton, :string, enum: Cantons.short_name_strings.map(&:upcase)
  mounted_attr :language, :string, enum: %w[DE FR IT], default: "DE", null: false
  mounted_attr :mitglied_termination_by_section_only, :boolean, default: false, null: false
  mounted_attr :tours_enabled, :boolean, default: false, null: false

  has_many :sac_section_membership_configs, dependent: :destroy, foreign_key: :group_id
  has_many :event_approval_commission_responsibilities, dependent: :destroy,
    class_name: "Event::ApprovalCommissionResponsibility"
  has_and_belongs_to_many :section_offerings, foreign_key: :group_id

  def sorting_name
    display_name.delete_prefix("SAC ").delete_prefix("CAS ")
  end

  def active_sac_section_membership_config
    @active_sac_section_membership_config ||= sac_section_membership_configs.active
  end
end
