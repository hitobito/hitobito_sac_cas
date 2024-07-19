require "spec_helper"

describe LayoutHelper do
  context "with multilanguage logo" do
    it "should return the logo for multilanguage image" do
      [:fr, :it, :de].each do |locale|
        I18n.with_locale(locale) do
          logo = "sac_logo_#{locale}.svg"
          allow(helper).to receive(:wagon_image_pack_tag).with(logo,
            alt: Settings.application.name).and_return logo

          expect(helper.header_logo).to eql(logo)
        end
      end

      I18n.with_locale(:en) do
        logo = "sac_logo_de.svg"
        allow(helper).to receive(:wagon_image_pack_tag).with(logo,
          alt: Settings.application.name).and_return logo

        expect(helper.header_logo).to eql(logo)
      end
    end
  end
end
