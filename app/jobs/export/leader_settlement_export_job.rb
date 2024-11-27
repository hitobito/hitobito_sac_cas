#  Copyright (c) 2022, Pfadibewegung Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class Export::LeaderSettlementExportJob < Export::ExportBaseJob
  self.parameters = PARAMETERS + [:participation_id, :iban]

  attr_reader :participation_id, :iban, :options

  def initialize(user_id, participation_id, iban, options)
    super(:pdf, user_id, options)
    @participation_id = participation_id
    @iban = iban
    @options = options
  end

  private

  def data = Export::Pdf::Participations::LeaderSettlement.new(participation, iban, options).render

  def participation = @participation = Event::Participation.find(participation_id)
end
