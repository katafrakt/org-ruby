require "spec_helper"
require "pathname"

describe OrgRuby::Parser do
  it "should open ORG files" do
    OrgRuby::Parser.load(RememberFile)
  end

  it "should fail on non-existant files" do
    expect { OrgRuby::Parser.load("does-not-exist.org") }.to raise_error
  end

  it "should load all of the lines" do
    parser = OrgRuby::Parser.load(RememberFile)
    expect(parser.lines.length).to eql(53)
  end

  it "should find all headlines" do
    parser = OrgRuby::Parser.load(RememberFile)
    expect(parser.headlines.count).to eq(12)
  end

  it "can find a headline by index" do
    parser = OrgRuby::Parser.load(RememberFile)
    line = parser.headlines[1].to_s
    expect(line).to eql("** YAML header in Webby\n")
  end

  it "should determine headline levels" do
    parser = OrgRuby::Parser.load(RememberFile)
    expect(parser.headlines[0].level).to eql(1)
    expect(parser.headlines[1].level).to eql(2)
  end

  it "should include the property drawer items from a headline" do
    parser = OrgRuby::Parser.load(FreeformExampleFile)
    expect(parser.headlines.first.property_drawer.count).to eq(2)
    expect(parser.headlines.first.property_drawer["DATE"]).to eq("2009-11-26")
    expect(parser.headlines.first.property_drawer["SLUG"]).to eq("future-ideas")
  end

  it "should put body lines in headlines" do
    parser = OrgRuby::Parser.load(RememberFile)
    expect(parser.headlines[0].body_lines.count).to eq(1)
    expect(parser.headlines[1].body_lines.count).to eq(7)
  end

  it "should understand lines before the first headline" do
    parser = OrgRuby::Parser.load(FreeformFile)
    expect(parser.header_lines.count).to eq(22)
  end

  it "should load in-buffer settings" do
    parser = OrgRuby::Parser.load(FreeformFile)
    expect(parser.in_buffer_settings.count).to eq(12)
    expect(parser.in_buffer_settings["TITLE"]).to eql("Freeform")
    expect(parser.in_buffer_settings["EMAIL"]).to eql("bdewey@gmail.com")
    expect(parser.in_buffer_settings["LANGUAGE"]).to eql("en")
  end

  it "should understand OPTIONS" do
    parser = OrgRuby::Parser.load(FreeformFile)
    expect(parser.options.count).to eq(33)
    expect(parser.options["TeX"]).to eql("t")
    expect(parser.options["todo"]).to eql("t")
    expect(parser.options["\\n"]).to eql("nil")
    expect(parser.options["H"]).to eq("3")
    expect(parser.options["num"]).to eq("t")
    expect(parser.options["toc"]).to eq("nil")
    expect(parser.options['\n']).to eq("nil")
    expect(parser.options["@"]).to eq("t")
    expect(parser.options[":"]).to eq("t")
    expect(parser.options["|"]).to eq("t")
    expect(parser.options["^"]).to eq("t")
    expect(parser.options["-"]).to eq("t")
    expect(parser.options["f"]).to eq("t")
    expect(parser.options["*"]).to eq("t")
    expect(parser.options["<"]).to eq("t")
    expect(parser.options["TeX"]).to eq("t")
    expect(parser.options["LaTeX"]).to eq("nil")
    expect(parser.options["skip"]).to eq("nil")
    expect(parser.options["todo"]).to eq("t")
    expect(parser.options["pri"]).to eq("nil")
    expect(parser.options["tags"]).to eq("not-in-toc")
    expect(parser.options["'"]).to eq("t")
    expect(parser.options["arch"]).to eq("headline")
    expect(parser.options["author"]).to eq("t")
    expect(parser.options["c"]).to eq("nil")
    expect(parser.options["creator"]).to eq("comment")
    expect(parser.options["d"]).to eq("(not LOGBOOK)")
    expect(parser.options["date"]).to eq("t")
    expect(parser.options["e"]).to eq("t")
    expect(parser.options["email"]).to eq("nil")
    expect(parser.options["inline"]).to eq("t")
    expect(parser.options["p"]).to eq("nil")
    expect(parser.options["stat"]).to eq("t")
    expect(parser.options["tasks"]).to eq("t")
    expect(parser.options["tex"]).to eq("t")
    expect(parser.options["timestamp"]).to eq("t")

    expect(parser.export_todo?).to be true
    parser.options.delete("todo")
    expect(parser.export_todo?).to be false
  end

  it "should skip in-buffer settings inside EXAMPLE blocks" do
    parser = OrgRuby::Parser.load(FreeformExampleFile)
    expect(parser.in_buffer_settings.count).to eq(0)
  end

  it "should return a textile string" do
    parser = OrgRuby::Parser.load(FreeformFile)
    expect(parser.to_textile).to be_kind_of(String)
  end

  it "should understand export table option" do
    fname = File.join(File.dirname(__FILE__), %w[html_examples skip-table.org])
    data = IO.read(fname)
    p = OrgRuby::Parser.new(data)
    expect(p.export_tables?).to be false
  end

  it "should add code block name as a line property" do
    example = <<~EXAMPLE
      * Sample
      
      #+name: hello_world
      #+begin_src sh :results output
      echo 'hello world'
      #+end_src
    EXAMPLE
    o = OrgRuby::Parser.new(example)
    h = o.headlines.first
    line = h.body_lines.find { |l| l.to_s == "#+begin_src sh :results output" }
    expect(line.properties["block_name"]).to eq("hello_world")
  end

  context "with a table that begins with a separator line" do
    let(:parser) { OrgRuby::Parser.new(data) }
    let(:data) { Pathname.new(File.dirname(__FILE__)).join("data", "tables.org").read }

    it "should parse without errors" do
      expect(parser.headlines.size).to eq(2)
    end
  end

  describe "Custom keyword parser" do
    fname = File.join(File.dirname(__FILE__), %w[html_examples custom-todo.org])
    p = OrgRuby::Parser.load(fname)
    valid_keywords = %w[TODO INPROGRESS WAITING DONE CANCELED]
    invalid_keywords = %w[TODOX todo inprogress Waiting done cANCELED NEXT |]
    valid_keywords.each do |kw|
      it "should match custom keyword #{kw}" do
        expect(kw =~ p.custom_keyword_regexp).to be_truthy
      end
    end
    invalid_keywords.each do |kw|
      it "should not match custom keyword #{kw}" do
        expect((kw =~ p.custom_keyword_regexp)).to be_nil
      end
    end
    it "should not match blank as a custom keyword" do
      expect(("" =~ p.custom_keyword_regexp)).to be_nil
    end
  end

  describe "Custom include/exclude parser" do
    fname = File.join(File.dirname(__FILE__), %w[html_examples export-tags.org])
    p = OrgRuby::Parser.load(fname)
    it "should load tags" do
      expect(p.export_exclude_tags.count).to eq(2)
      expect(p.export_select_tags.count).to eq(1)
    end
  end

  describe "Make it possible to disable rubypants pass" do
    it "should allow the raw dash" do
      org = "This is a dash -- that will remain as is."
      parser = OrgRuby::Parser.new(org, {skip_rubypants_pass: true})
      expected = "<p>#{org}</p>\n"
      expect(expected).to eq(parser.to_html)
    end
  end
end
