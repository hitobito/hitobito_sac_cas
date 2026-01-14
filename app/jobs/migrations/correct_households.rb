# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Migrations
  class CorrectHouseholds < BaseJob
    HOUSEHOLD_CORRECTION_QUERY = <<~SQL
      SELECT
        r1.family_id,
        STRING_AGG(DISTINCT r1.person_id::text, ';') AS person_ids
      FROM roles r
        LEFT JOIN people p ON p.id = r.person_id
        LEFT JOIN roles r1 ON r1.family_id = r.family_id
      WHERE r.type IN ('Group::SektionsMitglieder::Mitglied','Group::SektionsMitglieder::MitgliedZusatzsektion')
        AND current_date BETWEEN r.start_on AND r.end_on
        AND r.beitragskategorie = 'family'
        AND r.terminated = false
        AND p.household_key IS NULL
        AND r1.family_id NOT LIKE 'F%'
      GROUP BY r1.family_id
      ORDER BY r1.family_id;
    SQL

    Correction = Class.new do
      attr_reader :household_key, :ids
      def initialize(row)
        @household_key = row["family_id"]
        @ids = row["person_ids"].split(";")
      end

      def correct!
        if_valid do
          Rails.logger.warn "correcting #{self}"
          people.update_all(household_key:)
          main_person.update!(sac_family_main_person: true)
        end
      end

      def to_s = "#{household_key}: (#{ids.join(",")})"

      private

      def if_valid
        if main_person && (Person.where(household_key:) - people).none?
          yield
        else
          binding.pry
          Rails.logger.warn "invalid #{self}"
        end
      end

      def people
        @people ||= Person.where(id: ids)
      end

      def main_person
        @main_person ||= people
          .joins(:external_invoices)
          .where(external_invoices: {type: ExternalInvoice::SacMembership.sti_name})
          .first
      end
    end

    def perform
      PaperTrail.request.whodunnit = "Correct Households"
      Person.transaction do
        Role.connection.execute(HOUSEHOLD_CORRECTION_QUERY).to_a.map do |row|
          Correction.new(row).correct!
        end
        Correction.new("family_id" => "F53452", "person_ids" => "195836;204303").correct!
        fail "ouch"
      end
    end
  end
end
