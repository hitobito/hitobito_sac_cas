module SacImports
  class SeedGenerator
    IGNORED_COLUMNS = %w[id created_at updated_at]

    def self.generate_custom_contents
      new(CustomContent, :key).generate
      new(CustomContent::Translation, :custom_content_id, :locale).generate
    end

    def initialize(model, *keys)
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

    attr_reader :model, :keys, :mode, :file

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
      model.pluck(*cols).map do |row|
        cols.zip(row).to_h
      end
    end
  end
end
