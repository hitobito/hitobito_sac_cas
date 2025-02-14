class PhoneNumbersCleaner
  attr_reader :logger

  def initialize(log_level: Logger::INFO)
    ActiveRecord::Base.logger = nil
    @logger = Logger.new("/tmp/phone_cleaner.log", level: log_level)
  end

  def perform
    people_count = people.count

    people.find_each.with_index do |person, index|
      puts "#{index}/#{people_count}" if index % 100 == 0

      process_person(person)
    end
  end

  private

  def phone_numbers
    @phone_numbers ||=
      PhoneNumber
        # .where(contactable_type: "Person", contactable_id: 647212)
        .where.not(label: PhoneNumber.predefined_labels)
        .left_joins(:versions)
        .select("phone_numbers.*, MAX(COALESCE(versions.created_at, '1000-01-01 00:00:00')) updated_at")
        .group(:id)
  end

  def people
    Person.where(id: phone_numbers.map(&:contactable_id).uniq)
      .includes(:phone_numbers, :phone_number_mobile, :phone_number_landline)
  end

  def process_person(person)
    numbers_before = person.phone_numbers.map(&:to_s)

    numbers = [
      person.phone_number_mobile || latest_mobile(person)&.tap { |pn| pn.label = "mobile" },
      person.phone_number_landline || latest_landline(person)&.tap { |pn| pn.label = "landline" }
    ].compact

    log_msg = "Person #{person.id}: before: #{numbers_before.join(", ")}, after: #{numbers.map(&:to_s).join(", ")}"

    logger.info(log_msg)

    person.phone_numbers = numbers
    numbers.each { |number| number.save! if number.changed? }
  end

  def person_numbers(person) = phone_numbers.select { |pn| pn.contactable_id == person.id }

  def latest_mobile(person)
    numbers = person_numbers(person)
    numbers.select { |pn| pn.label =~ /Mobil/ }.max_by(&:updated_at) ||
      numbers.select { |pn|
        pn.label == "Haupt-Telefon" &&
          (pn.number.start_with?("+41") && pn.number =~ /\A\+41 7[6789] / || !pn.number.start_with?("+41"))
      }.max_by(&:updated_at) ||
      numbers.select { |pn|
        pn.label == "Privat" &&
          (pn.number.start_with?("+41") && pn.number =~ /\A\+41 7[6789] / || !pn.number.start_with?("+41"))
      }.max_by(&:updated_at)
  end

  def latest_landline(person)
    numbers = person_numbers(person)
    numbers.select { |pn|
      pn.label == "Haupt-Telefon" &&
        (pn.number.start_with?("+41") && pn.number !~ /\A\+41 7[6789] / || !pn.number.start_with?("+41"))
    }.max_by(&:updated_at) ||
      numbers.select { |pn|
        pn.label == "Privat" &&
          (pn.number.start_with?("+41") && pn.number !~ /\A\+41 7[6789] / || !pn.number.start_with?("+41"))
      }.max_by(&:updated_at)
  end
end
