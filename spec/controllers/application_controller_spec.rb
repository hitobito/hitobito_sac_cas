# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas

require "spec_helper"

# Serves as a basic proxy for ApplicationController
describe ChangelogController do
  include RoutesHelpers

  before { sign_in(people(:admin)) }

  let(:key) { "123abc" }
  let(:dom) { Capybara::Node::Simple.new(response.body) }

  render_views

  it "excludes tags if key is missing" do
    get :index
    expect(dom).not_to have_css "meta[name=description] + script", visible: false
    expect(dom).not_to have_css "footer + script", visible: false
  end

  it "includes tags if key is present" do
    allow(Settings).to receive_message_chain("google_tag_manager.key").and_return(key)
    get :index

    header = dom.find("meta[name=description] + script", visible: false)
    footer = dom.find("footer + script", visible: false)

    expect(header.native.to_s).to eq <<~HTML.strip
      <script>(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
      new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
      j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
      'https://www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
      })(window,document,'script','dataLayer','123abc');</script>
    HTML

    expect(footer.native.to_s).to eq <<~HTML.strip
      <script>
      //<![CDATA[

      <noscript><iframe src="https://www.googletagmanager.com/ns.html?id=123abc"
      height="-1" width="0" style="display:none;visibility:hidden"></iframe></noscript>

      //]]>
      </script>
    HTML
  end
end
