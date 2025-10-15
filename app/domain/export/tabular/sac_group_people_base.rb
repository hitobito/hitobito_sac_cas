# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module Export::Tabular
  class SacGroupPeopleBase < Export::Tabular::Base
    attr_reader :group

    def initialize(list, group)
      @group = group
      super(list)
    end

    def row_for(entry, format = nil)
      row_class.new(entry, group, format)
    end

    def model_class
      Person
    end

    def row_class
      @row_class ||= "#{self.class.name.to_s.singularize}Row".constantize
    end
  end
end
