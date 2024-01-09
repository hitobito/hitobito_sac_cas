# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::FutureRole
  extend ActiveSupport::Concern

  prepended do
    include SacCas::RoleBeitragskategorie
  end

  def start_on
    convert_on
  end

  def end_on
    convert_on.end_of_year
  end

  def build_new_role
    return super unless becomes_mitglied_role?

    super.tap do |role|
      role.created_at = convert_on
      role.delete_on = convert_on.end_of_year
    end
  end

  def validate_target_type?
    becomes_mitglied_role?
  end

  def becomes_mitglied_role?
    target_type <= SacCas::Role::MitgliedCommon || false
  end

  def to_s(format = :default)
    build_new_role.to_s(format)
  rescue ActiveRecord::RecordNotFound => err
    # It seems we can not build the target role, convert_to seems to be invalid.
    # Let's fall back gracefully.
    if err.message =~ /No role '.*' found/
      return "#{model_name.human} \"#{convert_to}\" (#{formatted_start_date})"
    end

    raise err
  end

  private

  # This method is called by the `before_validation` callback. It is used to
  # determine whether the beitragskategorie should be validated or not.
  # Only Mitglied roles have a beitragskategorie. So we only validate the
  # beitragskategorie if becomes_mitglied_role? is true.
  def validate_beitragskategorie?
    becomes_mitglied_role?
  end

  def set_beitragskategorie
    # only Mitglied roles have a beitragskategorie
    return unless becomes_mitglied_role?

    # We don't need to calculate the beitragskategorie if it is already set.
    return if beitragskategorie?

    # We need the convert_on date to calculate the beitragskategorie. But the
    # FutureRole is invalid anyway without a convert_on date. So we can safely
    # return here.
    return if convert_on.blank?

    # We need to calculate the beitragskategorie based on the convert_on date.
    self.beitragskategorie = ::SacCas::Beitragskategorie::Calculator
                             .new(person, reference_date: convert_on).calculate
  end

end
