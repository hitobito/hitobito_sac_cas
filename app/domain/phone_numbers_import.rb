class PhoneNumbersImport
  FIELD_ID = "Person_Id"
  FIELD_LANDLINE = "Festnetz"
  FIELD_MOBILE = "Mobile"
  FILE = "/tmp/phone_numbers.csv"

  attr_reader :logger

  def initialize(log_level: Logger::INFO)
    ActiveRecord::Base.logger = nil
    @logger = Logger.new("/tmp/phone_numbers.log", level: log_level)
  end

  def perform
    line_count = `wc -l #{FILE}`.to_i
    current_row = 0
    csv_enumerator.lazy.each_slice(1000) do |rows|
      people_ids = rows.map { |r| Integer(r[FIELD_ID]) }
      people_by_id = Person.includes(:phone_numbers).where(id: people_ids).index_by(&:id)
      phone_numbers_by_person_id = updated_phone_numbers(people_by_id.values)

      rows.each do |row|
        # next unless row[FIELD_ID].to_i == 180933

        current_row += 1
        puts "#{current_row}/#{line_count}" if current_row % 100 == 0
        person = people_by_id[Integer(row[FIELD_ID])]
        logger.warn("Person not found for id #{row[FIELD_ID]}") && next unless person

        process_person(person, row, phone_numbers_by_person_id[person.id])
      end
    end

    cleanup
  end

  private

  def csv_enumerator = CSV.foreach(FILE, headers: true)

  def updated_phone_numbers(people)
    PhoneNumber
      .joins("JOIN versions ON phone_numbers.id = versions.item_id AND item_type = 'PhoneNumber'")
      .where(contactable: people)
      .select("phone_numbers.*, versions.created_at AS updated_at")
      .distinct
      .group_by(&:contactable_id)
  end

  def process_person(person, row, updated_numbers)
    numbers_before = person.phone_numbers.map(&:to_s)
    numbers = []

    mobile_number = latest_mobile(row, updated_numbers)
    numbers << number_to_update(person, mobile_number, "mobile") if mobile_number

    landline_number = latest_landline(row, updated_numbers)
    numbers << number_to_update(person, landline_number, "landline") if landline_number

    return if numbers.empty? && numbers_before.empty? && row[FIELD_MOBILE].blank? && row[FIELD_LANDLINE].blank?

    log_msg = ["Person #{person.id}:"]
    log_msg << "  before: #{numbers_before.join(", ")}"
    log_msg << " updated: #{updated_numbers&.map(&:to_s)&.join(", ")}" if updated_numbers&.present?
    log_msg << "   after: #{numbers.map(&:to_s).join(", ")}"
    log_msg << "from csv: #{row[FIELD_MOBILE]} (mobile), #{row[FIELD_LANDLINE]} (landline)"

    logger.info(log_msg.join("\n"))

    person.phone_numbers = numbers
    numbers.each { |number| number.save! if number.changed? }
  end

  def number_to_update(person, number, label)
    except = ["mobile", "landline"].find { |l| l != label }
    number = person.phone_numbers.find { |pn| pn.number == number.number && pn.label != except } || number
    number.label = label
    number
  end

  def updated_mobile(updated_numbers)
    updated_numbers
      &.select { |pn| pn.label =~ /Mobil/ }
      &.max_by(&:updated_at) ||
      updated_numbers
        &.select { |pn| pn.label == "Haupt-Telefon" && pn.number =~ /\A\+41 7[6789] / }
        &.max_by(&:updated_at)
  end

  def updated_landline(updated_numbers)
    updated_numbers
      &.select { |pn| pn.label == "Privat" }
      &.max_by(&:updated_at) ||
      updated_numbers
        &.select { |pn| pn.label == "Haupt-Telefon" && pn.number.start_with?("+41") && pn.number !~ /\A\+41 7[6789] / }
        &.max_by(&:updated_at)
  end

  def navision_mobile(row)
    number = Phonelib.parse(row[FIELD_MOBILE])
    PhoneNumber.new(number: number.international, label: "mobile") if number.valid?
  end

  def navision_landline(row)
    number = Phonelib.parse(row[FIELD_LANDLINE])
    PhoneNumber.new(number: number.international, label: "landline") if number.valid?
  end

  def latest_mobile(row, updated_numbers)
    number = updated_mobile(updated_numbers) || navision_mobile(row)

    if row[FIELD_MOBILE].present? && number.nil?
      logger.warn("Invalid mobile number for person #{row[FIELD_ID]}: #{row[FIELD_MOBILE]}")
    end

    number
  end

  def latest_landline(row, updated_numbers)
    number = updated_landline(updated_numbers) || navision_landline(row)

    if row[FIELD_LANDLINE].present? && number.nil?
      logger.warn("Invalid landline number for person #{row[FIELD_ID]}: #{row[FIELD_LANDLINE]}")
    end

    number
  end

  def cleanup
    cleanup_group_numbers
    cleanup_people_numbers
  end

  def cleanup_group_numbers
    PhoneNumber.where(id: [
      188131,
      188132,
      188136,
      188137,
      188138
    ]).find_each { _1.update(label: "mobile") }

    PhoneNumber.where(id: [
      3,
      188133,
      188130,
      188134,
      188135
    ]).find_each { _1.update(label: "landline") }
  end

  def cleanup_people_numbers
    # PhoneNumber.where(contactable_type: 'Person').where.not(label: PhoneNumber.predefined_labels)
  end
end
