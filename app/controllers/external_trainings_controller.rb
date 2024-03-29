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
                          :remarks]

  decorates :group, :person

  # load parents before authorization
  prepend_before_action :parent
  before_render_form :load_event_kinds

  def create
    super(location: history_group_person_path(@group, @person)) do
      qualifier.issue if entry.valid?
    end
  end

  def destroy
    super(location: history_group_person_path(@group, @person)) do
      qualifier.revoke
    end
  end

  private

  def build_entry
    @person.external_trainings.build
  end

  def qualifier
    @qualifier ||= ExternalTrainings::Qualifier.new(@person, entry, 'participant')
  end

  def load_event_kinds
    @event_kinds ||= Event::Kind.list
  end
end
