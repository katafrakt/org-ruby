require "spec_helper"

describe OrgRuby::Headline do
  it "should recognize headlines that start with asterisks" do
    expect(OrgRuby::Headline.headline?("*** test\n")).to be_truthy
  end

  it "should reject headlines without headlines at the start" do
    expect(OrgRuby::Headline.headline?("  nope!")).to be_nil
    expect(OrgRuby::Headline.headline?("  tricked you!!!***")).to be_nil
  end

  it "should reject improper initialization" do
    expect { OrgRuby::Headline.new " tricked**" }.to raise_error
  end

  it "should properly determine headline level" do
    samples = ["* one", "** two", "*** three", "**** four"]
    expected = 1
    samples.each do |sample|
      h = OrgRuby::Headline.new sample
      expect(h.level).to eql(expected)
      expected += 1
    end
  end

  it "should properly determine headline level with offset" do
    h = OrgRuby::Headline.new("* one", nil, 1)
    expect(h.level).to eql(2)
  end

  it "should find simple headline text" do
    h = OrgRuby::Headline.new "*** sample"
    expect(h.headline_text).to eql("sample")
  end

  it "should understand tags" do
    h = OrgRuby::Headline.new "*** sample :tag:tag2:\n"
    expect(h.headline_text).to eql("sample")
    expect(h.tags.count).to eq(2)
    expect(h.tags[0]).to eql("tag")
    expect(h.tags[1]).to eql("tag2")
  end

  it "should understand a single tag" do
    h = OrgRuby::Headline.new "*** sample :tag:\n"
    expect(h.headline_text).to eql("sample")
    expect(h.tags.count).to eq(1)
    expect(h.tags[0]).to eql("tag")
  end

  it "should understand keywords" do
    h = OrgRuby::Headline.new "*** TODO Feed cat  :home:"
    expect(h.headline_text).to eql("Feed cat")
    expect(h.keyword).to eql("TODO")
  end

  it "should recognize headlines marked as COMMENT" do
    h = OrgRuby::Headline.new "* COMMENT This headline is a comment"
    expect(h.comment_headline?).to_not be_nil
  end
end
