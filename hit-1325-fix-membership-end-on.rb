require "csv"

class FixMembershipEndOn
  FILE = Wagons.find("sac_cas").root.join("tmp", "Bereinigung_Austrittsdatum.csv")

  attr_reader :logger, :data

  def initialize
    @logger = ActiveSupport::TaggedLogging.new(Logger.new(
      Wagons.find("sac_cas").root.join("tmp",
        "hit-1325-#{Time.zone.now.strftime("%Y%m%d%H%M")}.log"),
      level: :info
    ))
    @data = CSV.read(FILE, col_sep: ",", headers: true)
  end

  class Row
    attr_reader :role_id, :person_id, :previous_end_on, :corrected_end_on

    def initialize(csv_data)
      @role_id = csv_data[0]
      @person_id = csv_data[1]
      @previous_end_on = csv_data[4]
      @corrected_end_on = csv_data[7]
    end

    def to_s
      "<Row role_id: #{role_id}, person_id: #{person_id}, previous_end_on: #{previous_end_on}, corrected_end_on: #{corrected_end_on}>"
    end
  end

  def run
    PaperTrail.request.enabled = true
    PaperTrail.request.whodunnit = "HIT-1325 fix membership end_on"
    PaperTrail.request.controller_info = {mutation_id: SecureRandom.uuid,
whodunnit_type: "script"}

    process_end_on_correction
  end

  private

  def process_end_on_correction
    rows.each do |row|
      if active_membership_exists?(row)
        log(row, "has an active membership")

        next
      end

      if row.previous_end_on == row.corrected_end_on
        log(row, "already has the correct end_on")
      else
        correct_end_on(row)
      end
    end
  end

  def correct_end_on(row)
    Role.transaction do
      role = Role.with_inactive.find(row.role_id)

      role.update!(end_on: row.corrected_end_on)
    rescue ActiveRecord::RecordInvalid => e
      log(row, "role invalid on update: #{e}")
    rescue ActiveRecord::RecordNotFound => e
      log(row, "role not found: #{e}")
    end
  end

  def rows
    @rows ||= @data.map { Row.new(_1) }
  end

  def active_membership_exists?(row)
    people[row.person_id].sac_membership.active?
  end

  def people
    @people ||= rows.each_with_object({}) do |row, obj|
      obj[row.person_id] = Person.find(row.person_id)
    end
  end

  def log(row, line, level = :info)
    puts "[#{row}>] #{line}"
    logger.tagged(row) { logger.send(level, line) }
  end
end

FixMembershipEndOn.new.run
