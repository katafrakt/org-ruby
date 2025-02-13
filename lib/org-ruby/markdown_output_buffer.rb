require "stringio"

module OrgRuby
  class MarkdownOutputBuffer < OutputBuffer
    def initialize(output, opts = {})
      super(output)
      @options = opts
      @logger.debug "Markdown export options: #{@options.inspect}"
      @custom_blocktags = {} if @options[:markup_file]

      if @options[:markup_file]
        do_custom_markup
      end
    end

    def push_mode(mode, indent, properties = {})
      super
    end

    def pop_mode(mode = nil)
      m = super
      @list_indent_stack.pop
      m
    end

    # Maps org markup to markdown markup.
    MarkdownMap = {
      "*" => "**",
      "/" => "*",
      "_" => "*",
      "=" => "`",
      "~" => "`",
      "+" => "~~"
    }

    # Handles inline formatting for markdown.
    def inline_formatting(input)
      @re_help.rewrite_emphasis input do |marker, body|
        m = MarkdownMap[marker]
        "#{m}#{body}#{m}"
      end
      @re_help.rewrite_subp input do |type, text|
        if type == "_"
          "<sub>#{text}</sub>"
        elsif type == "^"
          "<sup>#{text}</sup>"
        end
      end
      @re_help.rewrite_links input do |link, defi|
        # We don't add a description for images in links, because its
        # empty value forces the image to be inlined.
        defi ||= link unless link&.match?(@re_help.org_image_file_regexp)
        link = link.gsub(/ /, "%%20")

        if defi&.match?(@re_help.org_image_file_regexp)
          "![#{defi}](#{defi})"
        elsif defi
          "[#{defi}](#{link})"
        else
          "[#{link}](#{link})"
        end
      end

      # Just reuse Textile special symbols for now?
      OrgRuby.special_symbols_to_textile(input)
      @re_help.restore_code_snippets input
    end

    # TODO: Implement this
    def output_footnotes!
      false
    end

    # Flushes the current buffer
    def flush!
      return false if @buffer.empty? && (@output_type != :blank)
      @logger.debug "FLUSH ==========> #{@output_type}"
      @buffer.gsub!(/\A\n*/, "")

      if mode_is_code?(current_mode)
        @output << "```#{@block_lang}\n"
        @output << @buffer << "\n"
        @output << "```\n"
      elsif preserve_whitespace?
        @output << @buffer << "\n"

      elsif @output_type == :blank
        @output << "\n"

      else
        case current_mode
        when :paragraph
          @output << "> " if @mode_stack[0] == :quote

        when :list_item
          @output << " " * @mode_stack.count(:list_item) << "* "

        when :horizontal_rule
          @output << "---"

        end
        @output << inline_formatting(@buffer) << "\n"
      end
      @buffer = ""
    end

    def add_line_attributes headline
      @output << "#" * headline.level
      @output << " "
    end
  end                           # class MarkdownOutputBuffer
end                             # module OrgRuby
