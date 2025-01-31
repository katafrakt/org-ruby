require "spec_helper"
require "pathname"

describe OrgRuby::Exporter do
  describe "Export to Textile test cases" do
    data_directory = File.join(File.dirname(__FILE__), "textile_examples")
    org_files = File.expand_path(File.join(data_directory, "*.org"))
    files = Dir.glob(org_files)
    files.each do |file|
      basename = File.basename(file, ".org")
      textile_name = File.join(data_directory, basename + ".textile")
      textile_name = File.expand_path(textile_name)

      it "should convert #{basename}.org to Textile" do
        expected = IO.read(textile_name)
        expect(expected).to be_kind_of(String)
        parser = OrgRuby::Parser.new(IO.read(file))
        actual = parser.to_textile
        expect(actual).to be_kind_of(String)
        expect(actual).to eq(expected)
      end
    end
  end

  describe "Export to HTML test cases" do
    # Dynamic generation of examples from each *.org file in html_examples.
    # Each of these files is convertable to HTML.
    data_directory = File.join(File.dirname(__FILE__), "html_examples")
    org_files = File.expand_path(File.join(data_directory, "*.org"))
    files = Dir.glob(org_files)
    files.each do |file|
      basename = File.basename(file, ".org")
      textile_name = File.join(data_directory, basename + ".html")
      textile_name = File.expand_path(textile_name)

      it "should convert #{basename}.org to HTML" do
        expected = IO.read(textile_name)
        expect(expected).to be_kind_of(String)
        parser = OrgRuby::Parser.new(IO.read(file), {allow_include_files: true})
        actual = parser.to_html
        expect(actual).to be_kind_of(String)
        expect(actual).to eq(expected)
      end

      it "should render #{basename}.org to HTML using Tilt templates" do
        ENV["ORG_RUBY_ENABLE_INCLUDE_FILES"] = "true"
        expected = IO.read(textile_name)
        template = Tilt.new(file).render
        expect(template).to eq(expected)
        ENV["ORG_RUBY_ENABLE_INCLUDE_FILES"] = ""
      end
    end

    it "should not render #+INCLUDE directive when explicitly indicated" do
      data_directory = File.join(File.dirname(__FILE__), "html_examples")
      expected = File.read(File.join(data_directory, "include-file-disabled.html"))
      org_file = File.join(data_directory, "include-file.org")
      parser = OrgRuby::Parser.new(IO.read(org_file), allow_include_files: false)
      actual = parser.to_html
      expect(actual).to eq(expected)
    end

    it "should render #+INCLUDE when ORG_RUBY_INCLUDE_ROOT is set" do
      data_directory = File.expand_path(File.join(File.dirname(__FILE__), "html_examples"))
      ENV["ORG_RUBY_INCLUDE_ROOT"] = data_directory
      expected = File.read(File.join(data_directory, "include-file.html"))
      org_file = File.join(data_directory, "include-file.org")
      parser = OrgRuby::Parser.new(IO.read(org_file))
      actual = parser.to_html
      expect(actual).to eq(expected)
      ENV["ORG_RUBY_INCLUDE_ROOT"] = nil
    end
  end

  describe "Export to HTML test cases with code syntax highlight disabled" do
    code_syntax_examples_directory = File.join(File.dirname(__FILE__), "html_code_syntax_highlight_examples")

    # Do not use syntax coloring for source code blocks
    org_files = File.expand_path(File.join(code_syntax_examples_directory, "*-no-color.org"))
    files = Dir.glob(org_files)

    files.each do |file|
      basename = File.basename(file, ".org")
      org_filename = File.join(code_syntax_examples_directory, basename + ".html")
      org_filename = File.expand_path(org_filename)

      it "should convert #{basename}.org to HTML" do
        expected = IO.read(org_filename)
        expect(expected).to be_kind_of(String)
        parser = OrgRuby::Parser.new(IO.read(file), {
          allow_include_files: true,
          skip_syntax_highlight: true
        })
        actual = parser.to_html
        expect(actual).to be_kind_of(String)
        expect(actual).to eq(expected)
      end

      it "should render #{basename}.org to HTML using Tilt templates",
        if: (defined? Coderay or defined? Pygments) do
        ENV["ORG_RUBY_ENABLE_INCLUDE_FILES"] = "true"
        expected = IO.read(org_filename)
        template = Tilt.new(file).render
        expect(template).to eq(expected)
        ENV["ORG_RUBY_ENABLE_INCLUDE_FILES"] = ""
      end
    end
  end

  ["coderay", "pygments"].each do |highlighter|
    if defined? (instance_eval highlighter.capitalize)
      xdescribe "Export to HTML test cases with code syntax highlight: #{highlighter}" do
        code_syntax_examples_directory = File.join(File.dirname(__FILE__), "html_code_syntax_highlight_examples")

        # Either Pygments or Coderay
        begin
          require highlighter
        rescue LoadError
          next
        end

        org_files = File.expand_path(File.join(code_syntax_examples_directory, "*-#{highlighter}.org"))
        files = Dir.glob(org_files)

        files.each do |file|
          basename = File.basename(file, ".org")
          org_filename = File.join(code_syntax_examples_directory, basename + ".html")
          org_filename = File.expand_path(org_filename)

          it "should convert #{basename}.org to HTML" do
            expected = IO.read(org_filename)
            expect(expected).to be_kind_of(String)
            parser = OrgRuby::Parser.new(IO.read(file), allow_include_files: true)
            actual = parser.to_html
            expect(actual).to be_kind_of(String)
            expect(actual).to eq(expected)
          end

          it "should render #{basename}.org to HTML using Tilt templates" do
            ENV["ORG_RUBY_ENABLE_INCLUDE_FILES"] = "true"
            expected = IO.read(org_filename)
            template = Tilt.new(file).render
            expect(template).to eq(expected)
            ENV["ORG_RUBY_ENABLE_INCLUDE_FILES"] = ""
          end
        end
      end
    end
  end

  describe "Export to Markdown test cases" do
    data_directory = File.join(File.dirname(__FILE__), "markdown_examples")
    org_files = File.expand_path(File.join(data_directory, "*.org"))
    files = Dir.glob(org_files)
    files.each do |file|
      basename = File.basename(file, ".org")
      markdown_name = File.join(data_directory, basename + ".md")
      markdown_name = File.expand_path(markdown_name)

      it "should convert #{basename}.org to Markdown" do
        expected = IO.read(markdown_name)
        expect(expected).to be_kind_of(String)
        parser = OrgRuby::Parser.new(IO.read(file), allow_include_files: false)
        actual = parser.to_markdown
        expect(actual).to be_kind_of(String)
        expect(actual).to eq(expected)
      end
    end
  end

  describe "Export to Markdown with incorrect custom markup test cases" do
    # The following tests export Markdown to the default markup of org-ruby
    # since the YAML file only contains the incorrect keys
    data_directory = File.join(File.dirname(__FILE__), "markdown_with_custom_markup_examples")
    org_files = File.expand_path(File.join(data_directory, "*.org"))
    files = Dir.glob(org_files)
    files.each do |file|
      basename = File.basename(file, ".org")
      default_html_name = File.join(data_directory, basename + "_default.md")
      default_html_name = File.expand_path(default_html_name)
      custom_markup_file = File.join(data_directory, "incorrect_markup_for_markdown.yml")
      custom_markup_file = File.expand_path(custom_markup_file)

      it "should convert #{basename}.org to Markdown with the default markup" do
        expected = IO.read(default_html_name)
        expect(expected).to be_kind_of(String)
        parser = OrgRuby::Parser.new(IO.read(file), {allow_include_files: true, markup_file: custom_markup_file})
        actual = parser.to_markdown
        expect(actual).to be_kind_of(String)
        expect(actual).to eq(expected)
      end
    end
  end

  describe "Export to Markdown with missing custom markup file test cases" do
    # The following tests export Markdown to the default markup of org-ruby
    # since the YAML file only contains the incorrect keys
    data_directory = File.join(File.dirname(__FILE__), "markdown_with_custom_markup_examples")
    org_files = File.expand_path(File.join(data_directory, "*.org"))
    files = Dir.glob(org_files)
    files.each do |file|
      basename = File.basename(file, ".org")
      default_html_name = File.join(data_directory, basename + "_default.md")
      default_html_name = File.expand_path(default_html_name)
      custom_markup_file = File.join(data_directory, "this_file_does_not_exists.yml")
      custom_markup_file = File.expand_path(custom_markup_file)

      it "should convert #{basename}.org to Markdown with the default markup" do
        expected = IO.read(default_html_name)
        expect(expected).to be_kind_of(String)
        parser = OrgRuby::Parser.new(IO.read(file), {allow_include_files: true, markup_file: custom_markup_file})
        actual = parser.to_markdown
        expect(actual).to be_kind_of(String)
        expect(actual).to eq(expected)
      end
    end
  end

  describe "Export to Markdown with custom markup test cases" do
    data_directory = File.join(File.dirname(__FILE__), "markdown_with_custom_markup_examples")
    org_files = File.expand_path(File.join(data_directory, "*.org"))
    files = Dir.glob(org_files)
    files.each do |file|
      basename = File.basename(file, ".org")
      markdown_name = File.join(data_directory, basename + ".md")
      markdown_name = File.expand_path(markdown_name)
      custom_markup_file = File.join(data_directory, "custom_markup_for_markdown.yml")
      custom_markup_file = File.expand_path(custom_markup_file)

      it "should convert #{basename}.org to Markdown with custom markup" do
        expected = IO.read(markdown_name)
        expect(expected).to be_kind_of(String)
        parser = OrgRuby::Parser.new(IO.read(file), {allow_include_files: false, markup_file: custom_markup_file})
        actual = parser.to_markdown
        expect(actual).to be_kind_of(String)
        expect(actual).to eq(expected)
      end
    end
  end

  describe "Export to HTML with incorrect custom markup test cases" do
    # The following tests export HTML to the default markup of org-ruby
    # since the YAML file only contains the incorrect keys
    data_directory = File.join(File.dirname(__FILE__), "html_with_custom_markup_examples")
    org_files = File.expand_path(File.join(data_directory, "*.org"))
    files = Dir.glob(org_files)
    files.each do |file|
      basename = File.basename(file, ".org")
      default_html_name = File.join(data_directory, basename + "_default.html")
      default_html_name = File.expand_path(default_html_name)
      custom_markup_file = File.join(data_directory, "incorrect_markup_for_html.yml")
      custom_markup_file = File.expand_path(custom_markup_file)

      it "should convert #{basename}.org to HTML with the default markup" do
        expected = IO.read(default_html_name)
        expect(expected).to be_kind_of(String)
        parser = OrgRuby::Parser.new(IO.read(file), {allow_include_files: true, markup_file: custom_markup_file})
        actual = parser.to_html
        expect(actual).to be_kind_of(String)
        expect(actual).to eq(expected)
      end
    end
  end

  describe "Export to HTML with missing custom markup file test cases" do
    # The following tests export HTML to the default markup of org-ruby
    # since the YAML file is missing.
    data_directory = File.join(File.dirname(__FILE__), "html_with_custom_markup_examples")
    org_files = File.expand_path(File.join(data_directory, "*.org"))
    files = Dir.glob(org_files)
    files.each do |file|
      basename = File.basename(file, ".org")
      default_html_name = File.join(data_directory, basename + "_default.html")
      default_html_name = File.expand_path(default_html_name)
      custom_markup_file = File.join(data_directory, "this_file_does_not_exists.yml")
      custom_markup_file = File.expand_path(custom_markup_file)

      it "should convert #{basename}.org to HTML with the default markup" do
        expected = IO.read(default_html_name)
        expect(expected).to be_kind_of(String)
        parser = OrgRuby::Parser.new(IO.read(file), {allow_include_files: true, markup_file: custom_markup_file})
        actual = parser.to_html
        expect(actual).to be_kind_of(String)
        expect(actual).to eq(expected)
      end
    end
  end

  describe "Export to HTML with custom markup test cases" do
    data_directory = File.join(File.dirname(__FILE__), "html_with_custom_markup_examples")
    org_files = File.expand_path(File.join(data_directory, "*.org"))
    files = Dir.glob(org_files)
    files.each do |file|
      basename = File.basename(file, ".org")
      custom_html_name = File.join(data_directory, basename + ".html")
      custom_html_name = File.expand_path(custom_html_name)
      custom_markup_file = File.join(data_directory, "custom_markup_for_html.yml")
      custom_markup_file = File.expand_path(custom_markup_file)

      it "should convert #{basename}.org to HTML with custom markup" do
        expected = IO.read(custom_html_name)
        expect(expected).to be_kind_of(String)
        parser = OrgRuby::Parser.new(IO.read(file), {allow_include_files: true, markup_file: custom_markup_file})
        actual = parser.to_html
        expect(actual).to be_kind_of(String)
        expect(actual).to eq(expected)
      end
    end
  end
end
