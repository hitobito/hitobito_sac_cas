# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.


class SelfRegistrationNeuanmeldung::Supplements
  include ActiveModel::Model
  include ActiveModel::Attributes
  include FutureRole::FormHandling

  include Rails.application.routes.url_helpers

  AGREEMENTS = [
    :statutes,
    :contribution_regulations,
    :data_protection,
  ].freeze

  AGREEMENTS.each do |agreement|
    attribute agreement, :boolean, default: false
    validates agreement, acceptance: true
  end

  attribute :section_statutes
  validates :section_statutes, acceptance: true

  attribute :promocode, :boolean
  attribute :newsletter, :boolean
  attribute :register_on, :string, default: :now
  attribute :self_registration_reason_id, :integer, default: -> { SelfRegistrationReason.first&.id }

  validates :register_on, presence: true

  attr_reader :section

  def initialize(params = {}, section = nil)
    super(params)
    @section = section
    self.section_statutes = false if section_statutes_attached? && section_statutes.nil?
  end

  def self.human_attribute_name(key, options = {})
    links = Regexp.new((AGREEMENTS + %w(section_statutes)).join('|'))
    case key
    when /self_registration_reason_id/ then Person.human_attribute_name(key.to_s.gsub(/_id/, ''))
    when /register_on/ then SelfInscription.human_attribute_name(key)
    when links then I18n.t("link_#{key}_title", scope: 'self_registration.infos_component')
    else super(key, options)
    end
  end

  def self_registration_reason_options
    SelfRegistrationReason.order(:created_at).collect do |r|
      [r.id.to_s, r.text]
    end
  end

  def section_statutes_attached?
    section&.privacy_policy&.attached?
  end

  def section_statutes_link_args
    label = I18n.t('link_section_statutes_title', scope: 'self_registration.infos_component')
    path = rails_blob_path(section.privacy_policy, disposition: :attachment, only_path: true)
    [label, path]
  end

  def link_translations(key)
    ["link_#{key}_title", "link_#{key}"].map do |str|
      I18n.t(str, scope: 'self_registration.infos_component')
    end
  end
end
