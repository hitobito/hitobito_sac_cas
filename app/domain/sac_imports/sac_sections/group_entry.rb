# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

module SacImports
  class SacSections::GroupEntry
    attr_reader :row

    def initialize(row)
      @row = row
    end

    def parent
      @parent ||= fetch_parent
    end

    def group_type
      (parent.id != Group.root.id) ? Group::Ortsgruppe : Group::Sektion
    end

    def group
      @group ||= group_type.find_or_initialize_by(navision_id: navision_id).tap do |group|
        group.archived_at = nil # archived groups cannot be updated
        assign_attributes(group)
      end
    end

    def valid?
      @valid ||= group.valid?
    end

    def errors
      @errors ||= valid? ? [] : build_error_messages
    end

    def section_name
      row.section_name.gsub(/^#{navision_id}\s/, "")
    end

    def import!
      group.save!
      setup_self_registration
      assign_membership_configs
      archive_group! if row.is_active == "0"
    end

    private

    def setup_self_registration
      neuanmeldungen_group.update!(custom_self_registration_title: self_registration_title)
    end

    def neuanmeldungen_group
      if row.self_registration_without_confirmation == "1"
        Group::SektionsNeuanmeldungenNv.find_by(parent_id: group.id)
      else
        Group::SektionsNeuanmeldungenSektion.find_or_create_by(parent_id: group.id)
      end
    end

    def self_registration_title
      t(row, "groups/self_registration.new.title", group_name: group.name)
    end

    def navision_id
      @navision_id ||= row.navision_id.to_i
    end

    def fetch_parent
      if row.level_3_id.present?
        return Group::Sektion.find_by(navision_id: row.level_2_id)
      end

      Group.root
    end

    def archive_group!
      # we cannot use default archive function since this is not possible
      # for groups with children
      # so just setting archived_at for now
      Group.where(layer_group_id: group.id).update_all(archived_at: Time.zone.now)
    end

    def parse_address
      address = row.address
      return if address.blank?

      Address::Parser.new(address).parse
    end

    def assign_attributes(group) # rubocop:disable Metrics/AbcSize
      group.id = navision_id
      group.parent = parent
      group.name = section_name

      group.postbox = row.postbox
      group.street, group.housenumber = parse_address
      group.zip_code = row.zip_code
      group.town = row.town

      group.foundation_year = row.foundation_year
      group.section_canton = row.canton
      group.language = language(row)
      group.mitglied_termination_by_section_only = row.termination_by_section_only == "1"

      build_phone_numbers(group)
      build_email(group)

      set_youth_homepage(row, group)
    end

    def assign_membership_configs
      CsvSource::NAV6MEMBERSHIP_CONFIGS.each do |key|
        membership_config.send(:"#{key}=", row.public_send(key))
      end
      membership_config.save!
    end

    def membership_config
      @membership_config ||=
        group.sac_section_membership_configs.find_or_initialize_by(group_id: group.id, valid_from: 2024)
    end

    def phone_valid?(number)
      number.present? && Phonelib.valid?(number)
    end

    def language(row)
      row.language[0..1].upcase
    end

    def set_youth_homepage(row, group)
      has_jo = row.has_jo == "1"
      return nil unless has_jo

      group.social_accounts.where(label: "Homepage Jugend").destroy_all
      group.social_accounts.build(name: row.youth_homepage, label: "Homepage Jugend")
    end

    def build_email(group)
      email = row.email&.downcase
      return unless email.present? && Truemail.valid?(email)

      group.email = email
    end

    def build_phone_numbers(group)
      # rubocop:disable Lint/SymbolConversion
      phone_numbers = {
        "Hauptnummer": row.phone
      }.freeze
      # rubocop:enable Lint/SymbolConversion

      phone_numbers.each do |label, number|
        group.phone_numbers.build(number: number, label: label) if phone_valid?(number)
      end
    end

    def build_error_messages
      group.errors.full_messages.join(", ")
    end

    def t(row, key, args)
      I18n.with_locale(group.language.downcase) do
        I18n.t(key, **args)
      end
    end
  end
end
