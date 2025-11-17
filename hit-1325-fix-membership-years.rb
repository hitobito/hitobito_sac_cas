require 'csv'

class FixMembershipYears
  FILE = Wagons.find("sac_cas").root.join("tmp", "NAV_AnzahlVereinsjahre_per20250415.csv")
  CORRECT_MEMBERSHIP_END_ON_FILE = Wagons.find("sac_cas").root.join("tmp", "Bereinigung_Austrittsdatum.csv")

  attr_reader :logger, :data

  def initialize
    @logger = ActiveSupport::TaggedLogging.new(Logger.new(
      Wagons.find("sac_cas").root.join("tmp",
        "hit-1325-fix-membership-years-#{Time.zone.now.strftime("%Y%m%d%H%M")}.log"),
      level: :info
    ))
    @data = CSV.read(FILE, col_sep: ',').to_h
  end

  def run
    PaperTrail.request.enabled = true
    PaperTrail.request.whodunnit = 'HIT-1325 fix membership years'
    PaperTrail.request.controller_info = { mutation_id: SecureRandom.uuid, whodunnit_type: 'script' }

    report_non_member_people

    Person.where(id: member_people_ids).preload_roles_unscoped.with_membership_years.find_each do |person|
      correct_years = data[person.id.to_s].to_i

      if person.membership_years == correct_years
        log(person, "already has correct membership years: #{correct_years}", :debug)
        next
      else
        correct_years(person, person.membership_years - correct_years)
      end
    end
  end

  private

  def member_people_ids
    @member_people_ids ||= Person.where(id: data.keys).joins(:roles_unscoped)
                                 .where(roles: { type: Group::SektionsMitglieder::Mitglied.sti_name })
                                 .select(:id).distinct.pluck(:id) & corrected_membership_end_on_person_ids
  end

  def corrected_membership_end_on_person_ids
    CSV.read(CORRECT_MEMBERSHIP_END_ON_FILE, col_sep: ",", headers: true).map { _1["person_id"] }
  end

  def log(person, line, level = :info)
    puts "[#{person.id}] #{line}"
    logger.tagged(person.id) { logger.send(level, line) }
  end

  def first_stammsektion_role(person)
    person.roles.select { |role| role.is_a?(Group::SektionsMitglieder::Mitglied) }&.min_by(&:start_on)
  end

  def correct_years(person, amount)
    role = first_stammsektion_role(person)
    log(person, "correcting onboarding date on role #{role.id} by #{amount} years")

    Role.transaction do
      role.start_on += amount.years
      role.valid? ||
        log(person,
            "role #{role.id} is invalid after changing start_on to #{role.start_on}") && raise(ActiveRecord::Rollback)

      role.save!(validate: false)
      person.roles.select { |r| SacCas::MITGLIED_ROLES.include?(r.type) && r != role }.each do |other_role|
        next if other_role.valid?

        if other_role.is_a?(Group::SektionsMitglieder::MitgliedZusatzsektion) &&
           other_role.active?(role.start_on) && other_role.start_on < role.start_on
          other_role.start_on = role.start_on
          other_role.save! && next if other_role.valid?
        end

        log(person, "other role #{other_role.id} is invalid after correcting years") && raise(ActiveRecord::Rollback)
      end
    end
  end

  def report_non_member_people
    non_member_people_ids = data.keys.map(&:to_i) - member_people_ids
    logger.debug("Personen ohne Stammsektionsrolle: #{non_member_people_ids.join(',')}")
  end
end

FixMembershipYears.new.run
