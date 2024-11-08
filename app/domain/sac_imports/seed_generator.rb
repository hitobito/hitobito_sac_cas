module SacImports
  class SeedGenerator
    IGNORED_COLUMNS = %w[id created_at updated_at]

    def self.generate_custom_contents
      new(CustomContent, keys: [:key]).generate
      new(CustomContent::Translation, keys: [:custom_content_id, :locale]).generate
      action_text_scope = ActionText::RichText.where(record_type: CustomContent::Translation.sti_name)
      new(ActionText::RichText, scope: action_text_scope, keys: [:record_id, :record_type]).generate
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
      cols = model.column_names - IGNORED_COLUMNS
      scope.pluck(*cols).map do |row|
        cols.zip(row).to_h
      end
    end
  end
end
