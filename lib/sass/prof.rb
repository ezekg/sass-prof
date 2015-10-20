require "sass/prof/version"

module Sass
  module Prof
    attr_accessor :settings, :function, :action, :args, :env

    @@t_then = Time.now
    @@t_now  = Time.now

    def initialize(function, action, args = nil, env = nil)
      @settings = Sass::Prof::Config
      @function = function
      @action   = action
      @args     = args
      @env      = env

      print_results
    end

    def fn_execution_time
      @@t_now = Time.now

      t_delta = (@@t_now.to_f - @@t_then.to_f) * 1000.0

      @@t_then, @@t_total = @@t_now, t_delta

      colorize(t_delta.to_s, :red).ljust 40
    end

    def fn_name(function)
      case
      when function.respond_to?(:name)
        function.name
      else
        nil
      end
    end

    def fn_args
      return nil if args.nil?

      args.to_s[1...args.length-2]
    end

    def fn_source
      return colorize("unknown file", :red).ljust 80 unless env

      original_filename = env.options.fetch :original_filename, "unknown file"
      filename          = env.options.fetch :filename, "unknown file"

      colorize("#{File.basename(original_filename)}:#{File.basename(filename)}",
        :yellow).ljust 80
    end

    def fn_action
      colorize(action.to_s, :green).ljust 40
    end

    def fn_signature
      colorize(fn_name, :blue) + colorize(fn_args, :black)
    end

    private

    def colorize(string, color)
      return unless string
      return string unless config.color

      colors = Hash.new("37").merge({
        :black  => "30",
        :red    => "31",
        :green  => "32",
        :yellow => "33",
        :blue   => "34",
        :purple => "35",
        :cyan   => "36",
        :white  => "37",
      })

      "\e[0;#{colors.fetch(color)}m#{string}\e[0m"
    end

    def print_results
      puts [fn_source, fn_execution_time, fn_action, fn_signature].join " | "

      if @@t_total > config.t_max && action == :execute
        puts colorize "max execution time of #{config.t_max}ms reached for"\
          " function `#{fn_name}`", :red
        exit
      end
    end

    module Config
      attr_accessor :t_max, :color

      def t_max
        @t_max ||= 100
      end

      def color
        @color = true if @color.nil?
        @color
      end
    end
  end

  class Tree::Visitors::Perform
    alias_method :_visit_function, :visit_function

    def visit_function(node)
      Sass::Prof.new node.dup, :declare
      _visit_function node
    end
  end

  class Script::Tree::Funcall
    alias_method :_perform_sass_fn, :perform_sass_fn

    def perform_sass_fn(function, args, splat, environment)
      Sass::Prof.new function.dup, :execute, args.dup, environment.dup
      _perform_sass_fn function, args, splat, environment
    end
  end
end
