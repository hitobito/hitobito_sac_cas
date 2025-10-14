module SacExports
  class SeedGenerator
    def self.generate_custom_contents
      new(CustomContent, keys: [:key]).generate
      new(CustomContent::Translation, keys: [:custom_content_id, :locale]).generate

      # rubocop:todo Layout/LineLength
      action_text_scope = ActionText::RichText.where(record_type: CustomContent::Translation.sti_name)
      # rubocop:enable Layout/LineLength
      new(ActionText::RichText, scope: action_text_scope, keys: [:record_id, :record_type]).generate

      new(ServiceToken, keys: [:token]).generate
      new(Oauth::Application, keys: [:uid]).generate
    end

    def initialize(model, scope: model.all, keys: [])
      @scope = scope
      @model = model
      @keys = keys
      @mode = :seed
      @file = Rails.root.join("tmp/#{model.table_name}_generated.rb")
    end

    def generate
      code = generate_code
      file.write(code)
      puts "Generating code written to #{file}" # rubocop:disable Rails/Output
    end

    def generate_code
      text = ""
      text << "#{model}.#{mode}(#{seed_keys}"
      rows.each do |row|
        text << ",\n#{row}"
      end
      text << ")\n"
    end

    private

    attr_reader :scope, :model, :keys, :mode, :file

    def seed_keys
      keys.map { |col| ":#{col}" }.join(" ,")
    end

    def rows
      scope.map { |model| model.attributes.transform_values(&:to_s) }
    end
  end
end
