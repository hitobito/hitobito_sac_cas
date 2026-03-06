module MigrateList
  # rubocop:disable Rails/Output

  class List
    attr_reader :section, :kind, :list

    delegate :id, :destroyed?, :update!, :destroy!, :people, to: :list

    def initialize(section, kind)
      @section = section
      @kind = kind
      @list = find_list(section, kind)
    end

    def subscriptions = list.subscriptions.people

    def read_people_ids = list.people.map(&:id)

    def people_ids = @people_ids ||= read_people_ids

    def subscriptions_counts
      @subscriptions_counts ||=
        subscriptions.group(:excluded).count
          .transform_keys { |key| key ? :excluding : :including }
    end

    def to_s(refresh = false)
      @people_ids = nil if refresh
      @subscriptions_counts = nil if refresh

      list_info = "#{list.group}(#{list.id}, #{kind}, #{list.subscribable_mode}"
      "#{list_info}): #{people_ids.count} #{subscriptions_counts}"
    end

    private

    def find_list(section, kind)
      MailingList
        .joins(:group)
        .find_by(internal_key: "sektionsbulletin_#{kind}", groups: {name: section})
    end
  end

  def run
    migrate_bulletins("SAC Weissenstein")
    migrate_bulletins("SAC Pfannenstiel")
    migrate_bulletins("SAC Kirchberg") do |paper, digital|
      digital.subscriptions.excluded.where(subscriber_id: paper.people_ids).destroy_all
      paper.destroy!
    end
  end

  def migrate_bulletins(section, dry_run: true) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    paper = List.new(section, :paper)
    digital = List.new(section, :digital)

    print_details_about(digital, paper)
    MailingList.transaction do
      digital.subscriptions.destroy_all
      paper.subscriptions.destroy_all

      digital.update!(subscribable_mode: :opt_out)
      paper.update!(subscribable_mode: :opt_in)

      digital_exclusions = digital.read_people_ids - digital.people_ids

      insert_subscription(digital, people_ids: digital_exclusions, excluded: true)
      insert_subscription(paper, people_ids: paper.people_ids, excluded: false)

      yield paper, digital if block_given?
      print_details_about(digital, paper, refresh: true)
      puts
      raise ActiveRecord::Rollback if dry_run
    end
  end

  def insert_subscription(list, people_ids:, excluded:)
    attrs = {subscriber_type: "Person", mailing_list_id: list.id, excluded:}
    rows = people_ids.map { |subscriber_id| attrs.merge(subscriber_id:) }
    Subscription.insert_all(rows)
  end

  def print_details_about(*lists, refresh: false)
    lists.reject(&:destroyed?).each { |list|
      puts list.to_s(refresh)
    }
  end
  # rubocop:enable Rails/Output
end
