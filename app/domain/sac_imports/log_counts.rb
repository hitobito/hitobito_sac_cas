# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacImports
  module LogCounts
    extend ActiveSupport::Concern

    # Usage:
    #   log_counts_delta(csv_report, Group, Role.with_inactive) {}
    #   log_counts_delta(csv_report,
    #     "Groups" => Group, "All Roles including inactive" => Role.with_inactive) {}
    def log_counts_delta(csv_report, *scopes, **labeled_scopes, &)
      raise "First argument must be SacImports::CsvReport" unless csv_report.is_a?(SacImports::CsvReport)

      data = calculate_deltas(scopes, labeled_scopes, &)
      table = AsciiTable.new(data)

      csv_report.log("\n#{table}\n")
    end

    private

    Definition = Data.define(:label, :scope, :model, :tally_by_type)

    def calculate_deltas(scopes, labeled_scopes, &block)
      definitions = prepare_definitions(label_scopes(scopes), tally_by_type: true) +
        prepare_definitions(labeled_scopes, tally_by_type: false)

      model_counts_before = definitions.each_with_object({}) do |d, counts|
        counts[d] = {total: d.scope.count}
        # also calculate counts by type if enabled and the model is an STI baseclass
        if d.tally_by_type && d.model.attribute_names.include?(d.model.inheritance_column) &&
            d.model.table_name == d.model.send(:undecorated_table_name, d.model.name)
          counts[d][:by_type] = d.scope.group(d.model.inheritance_column).count
        end
      end

      block.call

      data = [["Type", "Before", "After", "Delta"]]

      definitions.each do |d|
        total_before = model_counts_before[d][:total]
        total_after = d.scope.count
        delta = total_after - total_before
        data << [d.label, total_before, total_after, delta]

        if model_counts_before[d].key?(:by_type)
          after_by_type = d.scope.group(d.model.inheritance_column).count
          delta_by_type = after_by_type
            .merge(model_counts_before[d][:by_type]) { |_, after, before|
                            after.to_i -
                              before.to_i
                          }
            .select { |_, count| count != 0 }
          delta_by_type.keys.sort.each do |type|
            total_before = model_counts_before[d][:by_type][type]
            total_after = after_by_type[type]
            delta = delta_by_type[type]
            data << [type, total_before, total_after, delta]
          end
        end
      end
      data
    end

    def label_scopes(scopes)
      scopes.index_by do |scope|
        scope.respond_to?(:klass) ? scope.klass.sti_name : scope.sti_name
      end
    end

    def prepare_definitions(labeled_scopes, tally_by_type: false)
      labeled_scopes.map do |label, scope|
        model = scope.respond_to?(:klass) ? scope.klass : scope
        Definition.new(label:, scope:, model:, tally_by_type:)
      end
    end
  end
end
