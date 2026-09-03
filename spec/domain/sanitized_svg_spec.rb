# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SanitizedSvg do
  def sanitize(markup, **attributes)
    described_class.new(markup).to_svg(**attributes)
  end

  # Parsed as xml, not through Capybara, so that camel cased attribute names
  # like viewBox survive the assertion. Namespaces are dropped so that the
  # xpaths below need not spell out the svg one on every step.
  def parse(markup, **attributes)
    result = sanitize(markup, **attributes)
    result && Nokogiri::XML(result).tap(&:remove_namespaces!)
  end

  it "is nil for markup that is not an svg" do
    expect(sanitize("<html><body>nope</body></html>")).to be_nil
    expect(sanitize("not markup at all")).to be_nil
    expect(sanitize("")).to be_nil
  end

  it "declares the svg namespace" do
    expect(sanitize('<svg viewBox="0 0 24 24"><path d="M0 0Z"/></svg>'))
      .to include 'xmlns="http://www.w3.org/2000/svg"'
  end

  it "keeps the shapes and their geometry" do
    doc = parse(<<~SVG)
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 26">
        <g fill-rule="evenodd"><path fill-rule="nonzero" d="m8 3 4 8Z"/></g>
      </svg>
    SVG

    expect(doc.root["viewBox"]).to eq "0 0 24 26"
    expect(doc.at_xpath("//g")["fill-rule"]).to eq "evenodd"
    expect(doc.at_xpath("//path")["d"]).to eq "m8 3 4 8Z"
  end

  it "places the given attributes on the svg" do
    doc = parse('<svg viewBox="0 0 24 24"><path d="M0 0Z"/></svg>',
      class: "agenda-icon", style: "width: 1rem;")

    expect(doc.root["class"]).to eq "agenda-icon"
    expect(doc.root["style"]).to eq "width: 1rem;"
  end

  context "colours" do
    it "gives an svg without any fill one, so that it can be tinted" do
      doc = parse('<svg viewBox="0 0 24 24"><path d="M0 0Z"/></svg>')

      expect(doc.root["fill"]).to eq "currentColor"
    end

    it "keeps the colours an icon paints itself in" do
      doc = parse(<<~SVG)
        <svg viewBox="0 0 24 24" fill="#237100">
          <path d="M0 0Z" fill="rgb(1,2,3)" stroke="black" stroke-width="2"/>
        </svg>
      SVG

      expect(doc.root["fill"]).to eq "#237100"
      path = doc.at_xpath("//path")
      expect(path["fill"]).to eq "rgb(1,2,3)"
      expect(path["stroke"]).to eq "black"
      expect(path["stroke-width"]).to eq "2"
    end

    it "keeps currentColor, so that such an icon takes its surroundings' colour" do
      doc = parse(<<~SVG)
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <path d="M0 0Z" fill="currentColor" stroke="none"/>
        </svg>
      SVG

      expect(doc.root["fill"]).to eq "none"
      expect(doc.root["stroke"]).to eq "currentColor"
      path = doc.at_xpath("//path")
      expect(path["fill"]).to eq "currentColor"
      expect(path["stroke"]).to eq "none"
    end

    it "falls back for a reference to a gradient, whose definition it drops" do
      doc = parse(<<~SVG)
        <svg viewBox="0 0 24 24">
          <defs><linearGradient id="g"><stop stop-color="#fff"/></linearGradient></defs>
          <path d="M0 0Z" fill="url(#g)"/>
        </svg>
      SVG

      expect(doc.at_xpath("//defs")).to be_nil
      expect(doc.at_xpath("//path")["fill"]).to eq "currentColor"
    end
  end

  context "sanitizing" do
    it "drops scripts and event handlers" do
      doc = parse(<<~SVG)
        <svg viewBox="0 0 24 24" onload="alert(1)">
          <script>alert(2)</script>
          <path d="M0 0Z" onclick="alert(3)"/>
        </svg>
      SVG

      expect(doc.to_xml).not_to include "alert"
      expect(doc.root["onload"]).to be_nil
      expect(doc.at_xpath("//script")).to be_nil
      expect(doc.at_xpath("//path")["onclick"]).to be_nil
    end

    it "drops styles, which can pull in external resources" do
      doc = parse(<<~SVG)
        <svg viewBox="0 0 24 24">
          <style>path { fill: url(http://evil.example.com/x) }</style>
          <path d="M0 0Z" style="fill: red"/>
        </svg>
      SVG

      expect(doc.to_xml).not_to include "evil.example.com"
      expect(doc.at_xpath("//style")).to be_nil
      expect(doc.at_xpath("//path")["style"]).to be_nil
    end

    it "drops anything that embeds or references something else" do
      doc = parse(<<~SVG)
        <svg viewBox="0 0 24 24">
          <foreignObject><iframe src="http://evil.example.com"></iframe></foreignObject>
          <image href="http://evil.example.com/x.png"/>
          <use href="http://evil.example.com/x.svg#i"/>
          <a xlink:href="javascript:alert(1)" xmlns:xlink="http://www.w3.org/1999/xlink">
            <path d="M0 0Z"/>
          </a>
          <path d="M1 1Z"/>
        </svg>
      SVG

      expect(doc.to_xml).not_to include "evil.example.com"
      expect(doc.to_xml).not_to include "javascript"
      expect(doc.xpath("//path").map { |path| path.attr("d") }).to eq ["M1 1Z"]
    end

    it "drops ids and classes coming from the upload" do
      doc = parse('<svg viewBox="0 0 24 24"><path id="p" class="c" d="M0 0Z"/></svg>')

      path = doc.at_xpath("//path")
      expect(path["id"]).to be_nil
      expect(path["class"]).to be_nil
    end

    it "does not resolve entities" do
      doc = parse(<<~SVG)
        <?xml version="1.0"?>
        <!DOCTYPE svg [<!ENTITY xxe SYSTEM "file:///etc/passwd">]>
        <svg viewBox="0 0 24 24"><title>&xxe;</title><path d="M0 0Z"/></svg>
      SVG

      expect(doc.to_xml).not_to include "root:"
    end
  end
end
