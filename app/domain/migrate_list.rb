module MigrateList
  # rubocop:disable Rails/Output

  class List
    attr_reader :section, :kind, :list

    delegate :id, :subscriptions, :update!, :destroy!, to: :list

    def initialize(section, kind)
      @section = section
      @kind = kind
      @list = find_list(section, kind)
      @orig_people_ids = people_ids
      @orig_people_subscription_counts = people_subscription_counts
    end

    def people_ids = @list.people.pluck(:id)

    def people_subscription_counts
      list.subscriptions.people
        .group(:excluded).count.transform_keys { |key| key ? :excluding : :including }
    end

    def exists? = MailingList.where(id: list.id).exists?

    def to_s
      "#{list_info}: #{people_ids_count} #{people_subscription_infos}"
    end

    def people_ids_count
      [@orig_people_ids.count, people_ids.count].uniq.compact.join(" -> ")
    end

    def people_subscription_infos
      [@orig_people_subscription_counts, people_subscription_counts].uniq.compact.join(" -> ")
    end

    def list_info = "#{list.group}(#{list.id}, #{kind})"

    def deleted? = MailingList.where(id: list.id).none?

    private

    def find_list(section, kind)
      MailingList
        .joins(:group)
        .find_by(internal_key: "sektionsbulletin_#{kind}", groups: {name: section})
    end
  end

  def run
    # run_kirchberg
    run_common_case("SAC Weissenstein")
    run_common_case("SAC Pfannenstiel")
  end

  # Digital neu opt-out
  # -> kopiert bestehende Abmeldungen aufs digital (falls nicht auf digital subscribed)
  def run_kirchberg # rubocop:disable Metrics/AbcSize
    change_digital_to_opt_out("SAC Kirchberg") do |paper, digital, configured_ids|
      paper.subscriptions
        .people.excluding.where.not(subscriber_id: configured_ids)
        .update_all(mailing_list_id: digital.id)
      paper.destroy!
    end
  end

  def run_common_case(section)
    change_digital_to_opt_out(section) do |paper, digital, configured_ids|
      exclusion_attrs = {mailing_list_id: digital.id, subscriber_type: "Person", excluded: true}
      rows = people_as_configured(paper.list).pluck(:id).map do |subscriber_id|
        exclusion_attrs.merge(subscriber_id:)
      end
      Subscription.upsert_all(rows)
    end
  end

  # Digital neu opt-out
  # NOTE -> bestehende paper subscriber bekommen das bulletin 2x (ja/nein?)
  # NOTE -> globale Bedingung Rechnungsempfänger übernehmen?
  def change_digital_to_opt_out(section, dry_run: true) # rubocop:disable Metrics/AbcSize
    paper = List.new(section, :paper)
    digital = List.new(section, :digital)
    MailingList.transaction do
      puts paper
      puts digital
      configured_ids = people_as_configured(digital.list).pluck(:id)
      yield paper, digital, configured_ids if block_given?
      digital.subscriptions.people.included.where(subscriber_id: configured_ids).destroy_all
      digital.update!(subscribable_mode: :opt_out)
      puts digital if digital
      puts paper if paper.exists?
      raise ActiveRecord::Rollback if dry_run
    end
  end

  def people_as_configured(list)
    MailingLists::Subscribers.new(list).people_as_configured(use_people_subscriptions: false)
  end
  # rubocop:enable Rails/Output
end
