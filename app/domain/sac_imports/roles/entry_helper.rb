module SacImports::Roles::EntryHelper
  def skip(message)
    @skipped = true
    "Skipping: #{message}"
  end
end
