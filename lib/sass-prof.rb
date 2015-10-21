# encoding: UTF-8

module Sass
  module Prof

    class Profiler
      attr_accessor :config, :function, :action, :args, :env

      @@t_total = 0
      @@t_then  = 0
      @@t_now   = 0

      def initialize(function, action, args = nil, env = nil)
        @config   = Sass::Prof::Config
        @function = function
        @action   = action
        @args     = args
        @env      = env
      end

      def print_report
        report = to_table [fn_source, fn_execution_time, fn_action,
          fn_signature]

        puts report unless config.quiet

        if config.output_file
          File.open(config.output_file, "a+") { |f|
            f.puts report.gsub /\e\[(\d+)(;\d+)*m/, "" }
        end

        if @@t_total > config.t_max && action == :execute
          puts colorize "Max execution time of #{config.t_max}ms reached for"\
            " function `#{fn_name}` (took #{@@t_total.round(3)}ms)", :red
          exit
        end
      end

      def start
        @@t_then = Time.now
      end

      def stop
        @@t_now = Time.now
        t_delta = (@@t_now.to_f - @@t_then.to_f) * 1000.0
        @@t_then, @@t_total = @@t_now, t_delta
      end

      private

      def fn_execution_time
        color = @@t_total > config.t_max ? :red : :green
        colorize @@t_total.to_s, color
      end

      def fn_name
        case
        when function.respond_to?(:name)
          function.name
        else
          "unknown function"
        end
      end

      def fn_args
        return nil if args.nil?

        args.to_s[1...args.length-2]
      end

      def fn_source
        return colorize("unknown file", :red) unless env

        orig_filename = env.options.fetch :original_filename, "unknown file"
        filename      = env.options.fetch :filename, "unknown file"

        colorize "#{File.basename(orig_filename)}:#{File.basename(filename)}",
          :yellow
      end

      def fn_action
        colorize action.to_s, :yellow
      end

      def fn_signature
        colorize(fn_name, :blue) << "(" << colorize(fn_args, :purple) << ")"
      end

      def colorize(string, color)
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

      def to_table(columns)
        "[ %s ]" % columns.map { |col|
          "%-#{config.col_width}s" % col }.join(" | ")
      end
    end

    module Config
      attr_accessor :t_max, :col_width, :output_file, :quiet, :color

      def t_max
        @t_max ||= 100
      end

      def col_width
        @col_width = 20 if @col_width.nil?
        @col_width
      end

      def output_file
        @output_file = false if @output_file.nil?
        @output_file
      end

      def quiet
        @quiet = false if @quiet.nil?
        @quiet
      end

      def color
        @color = true if @color.nil?
        @color
      end

      extend self
    end
  end

  # class Tree::Visitors::Perform
  #   alias_method :_visit_function, :visit_function
  #
  #   def visit_function(node)
  #     prof = Prof::Profiler.new(node.dup, :allocate)
  #     prof.start
  #
  #     res = _visit_function node
  #
  #     prof.stop
  #     prof.print_report
  #
  #     res
  #   end
  # end

  class Script::Tree::Funcall
    alias_method :_perform_sass_fn, :perform_sass_fn

    def perform_sass_fn(function, args, splat, environment)
      prof = Prof::Profiler.new(function.dup, :execute, args.dup,
        environment.dup)
      prof.start

      res = _perform_sass_fn function, args, splat, environment

      prof.stop
      prof.print_report

      res
    end
  end
end
