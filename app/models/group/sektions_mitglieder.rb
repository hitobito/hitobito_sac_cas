# frozen_string_literal: true

#  Copyright (c) 2012-2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Group::SektionsMitglieder < ::Group
  self.static_name = true

  ### ROLES
  class Mitglied < ::Role
    include SacCas::Role::MitgliedStammsektion

    self.terminatable = true

    validates :delete_on, presence: {message: :must_be_present_unless_deleted},
      unless: :deleted_at?
  end

  class MitgliedZusatzsektion < ::Role
    include SacCas::Role::MitgliedZusatzsektion

    self.terminatable = true

    validates :delete_on, presence: {message: :must_be_present_unless_deleted},
      unless: :deleted_at?

    # This is used by the import as we don't have the complete memberhip history of a person
    # but have to import MitgliedZusatzsektion roles anyway.
    attr_accessor :skip_mitglied_during_validity_period_validation
  end

  class Ehrenmitglied < ::Role
    include SacCas::Role::ActiveMembershipValidations

    self.permissions = []
    self.basic_permissions_only = true
  end

  class Beguenstigt < ::Role
    include SacCas::Role::ActiveMembershipValidations

    self.permissions = []
    self.basic_permissions_only = true
  end

  class Leserecht < ::Role
    self.permissions = [:group_and_below_read]
  end

  class Schreibrecht < ::Role
    self.permissions = [:group_and_below_full]
  end

  roles Mitglied, MitgliedZusatzsektion, Ehrenmitglied, Beguenstigt, Leserecht, Schreibrecht
end
