begin
  require "tilt"

  module Tilt
    class OrgTemplate < Template
      def self.engine_initialized?
        defined? ::OrgRuby
      end

      def initialize_engine
        require "org-ruby"
      end

      def prepare
        @engine = OrgRuby::Parser.new(data)
        @output = nil
      end

      def evaluate(scope, locals, &block)
        @output ||= @engine.to_html
      end
    end
  end

  Tilt.register Tilt::OrgTemplate, "org"
rescue LoadError
  # Tilt is not available.
end
