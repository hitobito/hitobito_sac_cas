# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

class ExternalTrainingsController < CrudController
  self.nesting = Group, Person

  self.permitted_attrs = [:event_kind_id,
                          :name,
                          :provider,
                          :start_at,
                          :finish_at,
                          :training_days,
                          :link,
                          :remarks,
                          { other_people_ids: [] }]

  decorates :group, :person

  # load parents before authorization
  prepend_before_action :parent
  before_render_form :load_event_kinds
  before_render_form :load_other_people

  def create
    assign_attributes
    if ExternalTraining.transaction { save_entry }
      redirect_to(history_path, notice: create_success_message)
    else
      respond_with(entry)
    end
  end

  def destroy
    super(location: history_path)
  end

  private

  def history_path
    history_group_person_path(@group, @person)
  end

  def build_entry
    @person.external_trainings.build
  end

  def load_event_kinds
    @event_kinds = Event::Kind.list
  end

  def load_other_people
    @other_people = writables.where(id: entry.other_people_ids)
  end

  # need to clear out any potential non writable person ids
  def permitted_params
    super.tap do |p|
      next if p[:other_people_ids].blank?

      p[:other_people_ids] = writables.where(id: p[:other_people_ids]).pluck(:id) - [@person.id]
    end
  end

  def writables
    Person.accessible_by(PersonWritables.new(current_user))
  end

  def create_success_message
    return flash_message(:success) if entry.other_people_ids.blank?

    names = [entry.person.to_s] + Person.where(id: entry.other_people_ids).map(&:to_s)
    I18n.t("external_trainings.create.flash.success_multiple",
           model: full_entry_label,
           names: names.to_sentence)
  end
end
