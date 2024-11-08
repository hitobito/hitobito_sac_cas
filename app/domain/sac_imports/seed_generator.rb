module SacImports
  class SeedGenerator
    def self.generate_custom_contents
      new(CustomContent, keys: [:key]).generate
      new(CustomContent::Translation, keys: [:custom_content_id, :locale]).generate

      action_text_scope = ActionText::RichText.where(record_type: CustomContent::Translation.sti_name)
      new(ActionText::RichText, scope: action_text_scope, keys: [:record_id, :record_type]).generate

      new(ServiceToken, keys: [:token]).generate
      new(Oauth::Application, keys: [:uid]).generate
    end

    def self.import_custom_contents
      CustomContent.destroy_all

      load(Rails.root.join("tmp", "custom_contents.rb"))
      load(Rails.root.join("tmp", "custom_content_translations.rb"))
      load(Rails.root.join("tmp", "action_text_rich_texts.rb"))
      load(Rails.root.join("tmp", "service_tokens.rb"))
      load(Rails.root.join("tmp", "oauth_applications.rb"))
    end

    def initialize(model, scope: model.all, keys: [])
      @scope = scope
      @model = model
      @keys = keys
      @mode = :seed
      @file = Rails.root.join("tmp/#{model.table_name}.rb")
    end

    def generate
      code = generate_code
      file.write(code)
      puts "Generating code written to #{file}" # rubocop:disable Rails/Output
    end

    private

    attr_reader :scope, :model, :keys, :mode, :file

    def generate_code
      text = ""
      text << "#{model}.#{mode}(#{seed_keys}"
      rows.each do |row|
        text << ",\n#{row}"
      end
      text << ")\n"
    end

    def seed_keys
      keys.map { |col| ":#{col}" }.join(" ,")
    end

    def rows
      scope.map { |model| model.attributes.transform_values(&:to_s) }
    end
  end
end
