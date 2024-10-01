# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Event::Courses::KeyDataSheetsController < ApplicationController
  def create
    authorize!(:create, event)

    attach_key_data_sheets_to_event!

    redirect_to event, notice: t(".success")
  end

  private

  def attach_key_data_sheets_to_event!
    relevant_participations.each do |participation|
      pdf = Export::Pdf::Participations::KeyDataSheet.new(participation)
      create_attachment(pdf)
    end
  end

  def create_attachment(pdf)
    attachment = event.attachments.create!(visibility: :team)

    io = StringIO.new

    io.set_encoding(Settings.csv.encoding)

    io.write(pdf.render)
    io.rewind # make ActiveStorage's checksum-calculation deterministic

    attachment.file.attach(io: io, filename: pdf.filename.to_s)
  end

  def relevant_participations
    @relevant_participations ||= begin
      scope = event.participations

      scope = scope.where(id: params_participation_ids) if params_participation_ids.any?

      scope.joins(:roles).where(roles: {type: leader_event_role_types})
    end
  end

  def leader_event_role_types
    Event::Role.subclasses.select(&:leader?).map(&:sti_name)
  end

  def params_participation_ids
    list_param(:participation_ids)
  end

  def event
    @event ||= Event.find(params[:event_id])
  end
end
