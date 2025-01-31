module OrgRuby
  class Exporter
    attr_reader :parser

    def initialize(parser)
      @parser = parser
    end

    def to_html
      mark_trees_for_export
      export_options = {
        decorate_title: parser.in_buffer_settings["TITLE"],
        export_heading_number: parser.export_heading_number?,
        export_todo: parser.export_todo?,
        use_sub_superscripts: parser.use_sub_superscripts?,
        export_footnotes: parser.export_footnotes?,
        link_abbrevs: parser.link_abbrevs,
        skip_syntax_highlight: parser.parser_options[:skip_syntax_highlight],
        markup_file: parser.parser_options[:markup_file]
      }
      export_options[:skip_tables] = true if !parser.export_tables?
      output = ""
      output_buffer = HtmlOutputBuffer.new(output, export_options)

      if parser.in_buffer_settings["TITLE"]

        # If we're given a new title, then just create a new line
        # for that title.
        title = Line.new(parser.in_buffer_settings["TITLE"], self, :title)
        translate([title], output_buffer)
      end
      translate(parser.header_lines, output_buffer) unless parser.skip_header_lines?

      # If we've output anything at all, remove the :decorate_title option.
      export_options.delete(:decorate_title) if output.length > 0
      parser.headlines.each do |headline|
        next if headline.export_state == :exclude
        case headline.export_state
        when :exclude
          # NOTHING
        when :headline_only
          translate(headline.body_lines[0, 1], output_buffer)
        when :all
          translate(headline.body_lines, output_buffer)
        end
      end
      output << "\n"

      return output if parser.parser_options[:skip_rubypants_pass]

      rp = RubyPants.new(output)
      rp.to_html
    end

    def to_markdown
      mark_trees_for_export
      export_options = {
        markup_file: parser.parser_options[:markup_file]
      }
      output = ""
      output_buffer = MarkdownOutputBuffer.new(output, export_options)

      translate(parser.header_lines, output_buffer)
      parser.headlines.each do |headline|
        next if headline.export_state == :exclude
        case headline.export_state
        when :exclude
          # NOTHING
        when :headline_only
          translate(headline.body_lines[0, 1], output_buffer)
        when :all
          translate(headline.body_lines, output_buffer)
        end
      end
      output
    end

    def to_textile
      output = ""
      output_buffer = TextileOutputBuffer.new(output)

      translate(parser.header_lines, output_buffer)
      parser.headlines.each do |headline|
        translate(headline.body_lines, output_buffer)
      end
      output
    end

    private

    # Converts an array of lines to the appropriate format.
    # Writes the output to +output_buffer+.
    def translate(lines, output_buffer)
      output_buffer.output_type = :start
      lines.each { |line| output_buffer.insert(line) }
      output_buffer.flush!
      output_buffer.pop_mode while output_buffer.current_mode
      output_buffer.output_footnotes!
      output_buffer.output
    end

    # Uses export_select_tags and export_exclude_tags to determine
    # which parts of the org-file to export.
    def mark_trees_for_export
      marked_any = false
      # cache the tags
      select = parser.export_select_tags
      exclude = parser.export_exclude_tags
      inherit_export_level = nil
      ancestor_stack = []

      # First pass: See if any headlines are explicitly selected
      parser.headlines.each do |headline|
        ancestor_stack.pop while !ancestor_stack.empty? && (headline.level <= ancestor_stack.last.level)
        if inherit_export_level && (headline.level > inherit_export_level)
          headline.export_state = :all
        else
          inherit_export_level = nil
          headline.tags.each do |tag|
            if select.include? tag
              marked_any = true
              headline.export_state = :all
              ancestor_stack.each { |a| a.export_state = :headline_only unless a.export_state == :all }
              inherit_export_level = headline.level
            end
          end
        end
        ancestor_stack.push headline
      end

      # If nothing was selected, then EVERYTHING is selected.
      parser.headlines.each { |h| h.export_state = :all } unless marked_any

      # Second pass. Look for things that should be excluded, and get rid of them.
      parser.headlines.each do |headline|
        if inherit_export_level && (headline.level > inherit_export_level)
          headline.export_state = :exclude
        else
          inherit_export_level = nil
          headline.tags.each do |tag|
            if exclude.include? tag
              headline.export_state = :exclude
              inherit_export_level = headline.level
            end
          end
          if headline.comment_headline?
            headline.export_state = :exclude
            inherit_export_level = headline.level
          end
        end
      end
    end
  end
end
