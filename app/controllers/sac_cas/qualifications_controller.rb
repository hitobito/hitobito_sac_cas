# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

module SacCas::QualificationsController
  extend ActiveSupport::Concern

  def load_qualification_kinds
    super.tap do |qualification_kinds|
      @qualification_kinds = qualification_kinds.to_a.keep_if do |qualification_kind|
        can?(:create, @person.qualifications.new(qualification_kind: qualification_kind))
      end
    end
  end

  def save_entry
    entry.save context: :qualifications_controller
  rescue Mysql2::Error => e
    Airbrake.notify(e, parameters: params)
    logger.error e.message
    false
  end

  def permitted_attrs
    permitted = self.class.permitted_attrs.dup

    permitted << :finish_at if finish_at_manually_editable?

    permitted
  end

  def finish_at_manually_editable?
    param_qualification_kind&.finish_at_manually_editable?
  end

  def param_qualification_kind
    QualificationKind.find_by(id: params.dig(:qualification, :qualification_kind_id))
  end

end
