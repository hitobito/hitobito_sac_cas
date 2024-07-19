class SelfRegistration::Sektion < SelfRegistration::Base
  MIN_ADULT_YEARS = SacCas::Beitragskategorie::Calculator::AGE_RANGE_ADULT.begin

  attr_accessor :housemates_attributes, :supplements_attributes

  self.partials += [:household, :supplements]
  self.main_person_class = SelfRegistration::Sektion::MainPerson

  def initialize(group:, params:)
    super
    @group = group
    @housemates_attributes = extract_attrs(params, :housemates_attributes, array: true).to_a
    @supplements_attributes = extract_attrs(params, :supplements_attributes)
  end

  def partials
    return self.class.partials - [:household] if too_young_for_household?

    super
  end

  def save!
    super.then do |_success|
      housemates.all?(&:save!)
    end
  end

  def housemates
    @housemates ||= build_housemates
  end

  def supplements
    @supplements ||= Supplements.new(@supplements_attributes, @group)
  end

  def birthdays
    housemates.collect(&:birthday).unshift(main_person.birthday).compact.shuffle
  end

  def build_housemate
    build_person({}, Housemate)
  end

  private

  def household_valid?
    housemates.all?(&:valid?)
  end

  def supplements_valid?
    supplements.valid?
  end

  def build_person(*args)
    super do |attrs|
      attrs.merge(
        household_key: household_key,
        supplements: supplements
      )
    end
  end

  def build_housemates(adult_count = 1)
    @housemates_attributes.map do |attrs|
      next if attrs[:_destroy] == "1"
      next if too_young_for_household?

      build_person(attrs.merge(adult_count: adult_count), Housemate).tap do |mate|
        mate.household_emails = household_emails
        adult_count += 1 if mate.person.adult?
      end
    end.compact
  end

  def household_key
    @household_key ||= Household.new(Person.new).send(:next_key) if household?
  end

  def household_emails
    (housemates_attributes + [main_person_attributes]).pluck(:email).compact
  end

  def household?
    @housemates_attributes.present? && !too_young_for_household?
  end

  def too_young_for_household?
    years = ::Person.new(birthday: @main_person_attributes[:birthday]).years
    years && years <= MIN_ADULT_YEARS
  end
end
