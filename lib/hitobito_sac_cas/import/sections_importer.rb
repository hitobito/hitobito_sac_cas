# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require Rails.root.join('lib', 'import', 'xlsx_reader.rb')

module Import
  class SectionsImporter

    HEADERS = {
      navision_id: 'Sektionscode',
      description: 'Beschreibung',
      parent_level_1: 'Level 1',
      parent_level_2: 'Level 2',
      parent_level_3: 'Level 3',
      inactive: 'Inaktiv',
      address_supplement: 'Adresszusatz',
      address: 'Adresse',
      town: 'Ort',
      zip_code: 'PLZ',
      section_canton: 'Kanton',
      postfach: 'Postfach',
      phone: 'Telefon',
      email: 'E-Mail',
      homepage: 'Homepage',
      youth_homepage: 'Homepage Jugend',
      zv_registrations: 'Mitgliederaufnahme durch GS',
      locale: 'Sprachcode',
      foundation_year: 'Gründungsjahr',
    }

    attr_reader :output

    def initialize(path, output: STDOUT)
      raise 'Sektion Export excel file not found' unless path.exist?
      @path = path
      @output = output
    end

    def import!
      without_query_logging do
        Import::XlsxReader.read(@path, 'Data', headers: HEADERS) do |row|
          output.puts "Importing row #{row[:description]}"
          group = group_for(row)
          ignoring_archival do
            group = set_data(row, group)
            group.save!
            update_subgroups(row, group)
          end
          output.puts "Finished importing #{group.name}"
        rescue ActiveRecord::ReadOnlyRecord
          output.puts 'ERROR: Cannot modify archived group'
          output.puts group.inspect
        end
        rebuild_group_hierachy
        output.puts 'Done.'
      end
    end

    private

    def rebuild_group_hierachy
      output.puts 'Rebuilding group hierarchy...'
      ignoring_archival do
        Group.update_all(lft: nil, rgt: nil)
        Group.rebuild!(false)
      end
    end

    def without_query_logging
      old_logger = ActiveRecord::Base.logger
      ActiveRecord::Base.logger = nil
      yield
      ActiveRecord::Base.logger = old_logger
    end

    def ignoring_archival
      old_value = Group.archival_validation
      Group.archival_validation = false
      yield
      Group.archival_validation = old_value
    end

    def group_for(row)
      # TODO handle case where root group does not exist yet?
      if root?(row)
        group = Group.root
        group.navision_id = '1000'
        return group
      end

      Group.find_or_initialize_by(navision_id: navision_id(row))
    end

    def set_data(row, group)
      group.type = type(row)&.name
      group = group.becomes(type(row))
      group.name = root?(row) ? 'SAC/CAS' : section_name(row)
      group.parent_id = parent_id(row)
      group.address = address(row)
      set_phone(row, group)
      group.email = email(row)
      set_homepage(row, group)
      set_youth_homepage(row, group)
      group.archived_at = archived_at(row)
      set_foundation_year(row, group)
      set_section_canton(row, group)
      group
    end

    def section_name(row)
      return description(row) unless description(row) =~ /^#{Regexp.quote(navision_id(row))} (.*)$/
      Regexp.last_match(1)
    end

    def parent(row)
      return nil if root?(row)

      # TODO fix the bug in the navision data export which requires this wrong ordering...
      levels = [row[:parent_level_2], row[:parent_level_3], row[:parent_level_1]].select(&:present?)
      parent = Group.find_by(navision_id: levels[1].to_s)
      raise levels[1].to_s unless parent&.id
      # Use the second to last present level as the parent navision_id
      parent
    rescue
      output.puts "WARNING: No parent found for row #{row.inspect}"
      Group.root
    end

    def parent_id(row)
      parent(row)&.id
    end

    def type(row)
      return Group::SacCas if root?(row)
      parent_group = parent(row)
      return Group::Sektion if parent_group.navision_id == '1000'
      Group::Ortsgruppe
    end

    def root?(row)
      navision_id(row) == '1000'
    end

    def navision_id(row)
      row[:navision_id].to_s
    end

    def description(row)
      row[:description].to_s
    end

    def set_foundation_year(row, group)
      return unless group.respond_to?(:foundation_year=)

      group.foundation_year = row[:foundation_year].to_i
    end

    def set_section_canton(row, group)
      return unless group.respond_to?(:section_canton=)

      group.section_canton = row[:section_canton].to_s.presence&.upcase
    end

    def archived_at(row)
      # TODO fix the bug in the navision data export which marks the root group as inactive
      !root?(row) && row[:inactive] == 'Ja' ? Date.today : nil
    end

    def address(row)
      [
        row[:address_supplement],
        row[:address],
        row[:postfach],
        zip_code_and_town(row),
      ].select(&:present?).join("\n")
    end

    def zip_code_and_town(row)
      [row[:zip_code].to_s, row[:town]].select(&:present?).join(' ')
    end

    def set_phone(row, group)
      phone = row[:phone]
      return unless phone.present? && Phonelib.valid?(phone)
      group.phone_numbers.destroy_all
      group.phone_numbers.build(number: phone, label: section_name(row))
    end

    def email(row)
      email = row[:email]
      return nil unless email.present? && Truemail.valid?(email)
      email
    end

    def set_homepage(row, group)
      homepage = row[:homepage]
      return unless homepage.present?
      group.social_accounts.destroy_all
      group.social_accounts.build(name: homepage, label: 'Homepage')
    end

    def set_youth_homepage(row, group)
      homepage = row[:youth_homepage]
      return unless homepage.present?
      group.social_accounts.destroy_all
      group.social_accounts.build(name: homepage, label: 'Homepage Jugend')
    end

    def update_subgroups(row, group) # rubocop:disable Metrics/MethodLength
      return if root?(row)

      if zv_registrations(row)
        neuanmeldungen = Group::SektionsNeuanmeldungenNv.find_by!(parent_id: group.id)
        neuanmeldungen.update!(
          self_registration_role_type: Group::SektionsNeuanmeldungenNv::Neuanmeldung,
          custom_self_registration_title: self_registration_title(row, group),
          deleted_at: nil)
      else
        Group::SektionsNeuanmeldungenSektion.create!(
          parent_id: group.id,
          self_registration_role_type: Group::SektionsNeuanmeldungenSektion::Neuanmeldung,
          custom_self_registration_title: self_registration_title(row, group),
          deleted_at: nil)
      end
    end

    def self_registration_title(row, group)
      t(row, 'groups/self_registration.new.title', group_name: group.name)
    end

    def zv_registrations(row)
      row[:zv_registrations].to_s == 'Ja'
    end

    def locale(row)
      {
        'DES' => 'de',
        'FRS' => 'fr',
        'ITS' => 'it',
      }.fetch(row[:locale].to_s, 'de')
    end

    def t(row, key, args)
      I18n.with_locale(locale(row)) do
        I18n.translate(key, **args)
      end
    end
  end
end
