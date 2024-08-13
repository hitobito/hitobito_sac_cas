# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

Fabricator(:person_data_quality_issue, class_name: "Person::DataQualityIssue") do
  person
  attr { Person.column_names.sample }
  key { "todo-in-other-ticket" }
  severity { Person::DataQualityIssue.severities.key(rand(1..3)) }
end
