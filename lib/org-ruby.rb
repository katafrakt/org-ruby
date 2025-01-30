# internal requires
require "org-ruby/version"
require "org-ruby/parser"
require "org-ruby/regexp_helper"
require "org-ruby/line"
require "org-ruby/headline"
require "org-ruby/output_buffer"

# HTML exporter
require "org-ruby/html_output_buffer"
require "org-ruby/html_symbol_replace"

# Textile exporter
require "org-ruby/textile_output_buffer"
require "org-ruby/textile_symbol_replace"

# Markdown exporter
require "org-ruby/markdown_output_buffer"

# Tilt support
require "org-ruby/tilt"

module OrgRuby
  # :stopdoc:
  LIBPATH = __dir__ + ::File::SEPARATOR
  PATH = ::File.dirname(LIBPATH) + ::File::SEPARATOR
  # :startdoc:

  # Returns the version string for the library.
  #
  def self.version
    VERSION
  end
end
