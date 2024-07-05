# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class SelfRegistration::Sektion::Supplements
  include ActiveModel::Model
  include ActiveModel::Attributes
  include FutureRole::FormHandling

  include Rails.application.routes.url_helpers

  AGREEMENTS = [
    :statutes,
    :contribution_regulations,
    :data_protection
  ].freeze

  DYNAMIC_AGREEMENTS = [
    :sektion_statuten,
    :adult_consent
  ]

  AGREEMENTS.each do |agreement|
    attribute agreement, :boolean, default: false
    validates agreement, acceptance: true
  end

  DYNAMIC_AGREEMENTS.each do |agreement|
    attribute agreement, :boolean
    validates agreement, acceptance: true, if: :"requires_#{agreement}?"
  end

  attribute :newsletter, :boolean
  attribute :register_on, :string, default: :now
  attribute :self_registration_reason_id, :integer, default: :first_self_registration_reason_id

  validates :register_on, presence: true

  def initialize(params = {}, group)
    super(params)
    @group = group

    set_default_false_if_required(:adult_consent)
    set_default_false_if_required(:sektion_statuten)
  end

  def self.human_attribute_name(key, options = {})
    links = Regexp.new((AGREEMENTS + %w[sektion_statuten]).join("|"))
    case key
    when /self_registration_reason_id/ then Person.human_attribute_name(key.to_s.gsub("_id", ""))
    when /register_on/ then SelfInscription.human_attribute_name(key)
    when links then I18n.t("link_#{key}_title", scope: "self_registration.infos_component")
    else super
    end
  end

  def self_registration_reason_options
    SelfRegistrationReason.order(:created_at).collect do |r|
      [r.id.to_s, r.text]
    end
  end

  def sektion_statuten_link_args
    label = I18n.t("link_sektion_statuten_title", scope: "self_registration.infos_component")
    path = rails_blob_path(privacy_policy, disposition: :attachment, only_path: true)
    [label, path]
  end

  def link_translations(key)
    ["link_#{key}_title", "link_#{key}"].map do |str|
      I18n.t(str, scope: "self_registration.infos_component")
    end
  end

  def requires_sektion_statuten?
    sektion_statuten.blank? && privacy_policy.attached?
  end

  def requires_adult_consent?
    @group.self_registration_require_adult_consent?
  end

  private

  def set_default_false_if_required(key)
    send(:"#{key}=", false) if send(key).blank? && send(:"requires_#{key}?")
  end

  def first_self_registration_reason_id
    SelfRegistrationReason.first&.id
  end

  def privacy_policy
    @group.layer_group.privacy_policy
  end
end
