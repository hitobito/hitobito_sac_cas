# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

namespace :oneoff do
  namespace :migrate_emergency_contacts do
    desc "List the legacy emergency contact question templates (id | group_id | default | text)"
    task list_templates: :environment do
      rows = Migrations::EmergencyContactAnswersMigrator.new.list_templates
      puts "ID | GroupID | Default | Event-Type | Question-Text"
      rows.each do |id, group_id, default, event, text|
        puts "#{id} | #{group_id} | #{default} | #{event} | #{text}"
      end
    end

    desc "Copy the 2027 emergency contact answers into the person columns " \
      "(optional TEMPLATE_IDS=<comma separated ids>)"
    task copy_answers: :environment do
      updated = Migrations::EmergencyContactAnswersMigrator
        .new(template_ids: template_ids).copy_answers
      puts "Updated #{updated} emergency contact entries"
    end

    desc "Remove the legacy emergency contact questions, answers and templates " \
      "(optional TEMPLATE_IDS=<comma separated ids>)"
    task remove_legacy_questions: :environment do
      Migrations::EmergencyContactAnswersMigrator
        .new(template_ids: template_ids).remove_legacy_questions
      puts "Removed legacy questions"
    end

    def template_ids
      ENV["TEMPLATE_IDS"].to_s.split(",").map(&:to_i).reject(&:zero?)
    end
  end
end
