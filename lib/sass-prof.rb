# encoding: UTF-8

module Sass
  module Prof

    module Config
      attr_accessor :t_max, :col_width, :output_file, :quiet, :color

      @t_max       = 100
      @col_width   = 20
      @output_file = false
      @quiet       = false
      @color       = true

      extend self
    end

    module Report
      attr_accessor :report

      @report = [
        ["File", "Execution Time", "Action", "Signature"]
      ]

      def add(value)
        @report << value
      end

      def print_report
        puts to_table @report
      end

      def reset_report
        @report = [
          ["File", "Execution Time", "Action", "Signature"]
        ]
      end

      def to_table(report)
        return unless report

        table = report.map do |row|
          "[ %s ]" % row.map { |col|
            diff = col.length - col.gsub(/\e\[(\d+)(;\d+)*m/, "").length
            "%-#{Sass::Prof::Config.col_width + diff}s" % col }.join(" | ")
        end

        table.join "\n"
      end

      extend self
    end

    class Profiler
      attr_accessor :config, :function, :action, :args, :env

      @@t_total = 0
      @@t_then  = 0
      @@t_now   = 0

      def initialize(function, action, args = nil, env = nil)
        @config   = Sass::Prof::Config
        @report   = Sass::Prof::Report
        @function = function
        @action   = action
        @args     = args
        @env      = env
      end

      def start
        @@t_then = Time.now
      end

      def stop
        @@t_now = Time.now
        t_delta = (@@t_now.to_f - @@t_then.to_f) * 1000.0
        @@t_then, @@t_total = @@t_now, t_delta

        prep_fn_report
      end

      private

      def prep_fn_report
        fn_report = [fn_source, fn_execution_time, fn_action,
          fn_signature]

        @report.add fn_report unless config.quiet

        if config.output_file
          File.open(config.output_file, "a+") do |f|
            f.puts @report.to_table [fn_report.map { |col|
              col.gsub /\e\[(\d+)(;\d+)*m/, "" }]
          end
        end

        if @@t_total > config.t_max && action == :execute
          raise Sass::RuntimeError.new "Max execution time of #{config.t_max}ms"\
            " reached for function `#{fn_name}` (took #{@@t_total.round(3)}ms)"
        end
      end

      def fn_execution_time
        color = @@t_total > config.t_max ? :red : :green
        colorize @@t_total.to_s, color
      end

      def fn_name
        case
        when function.respond_to?(:name)
          function.name
        else
          "Unknown function"
        end
      end

      def fn_args
        return nil if args.nil?

        if args.is_a? Array
          args.map { |a| a.inspect }.join(", ")
        else
          args.to_s[1...args.length-2]
        end
      end

      def fn_source
        return colorize("Unknown file", :red) unless env

        orig_filename = env.options.fetch :original_filename, "Unknown file"
        filename      = env.options.fetch :filename, "Unknown file"

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
    end
  end

  class Tree::Visitors::Perform
    alias_method :__visit_function, :visit_function

    def visit_function(node)
      prof = Sass::Prof::Profiler.new(node.dup, :allocate)
      prof.start

      value = __visit_function node

      prof.stop

      value
    end
  end

  class Script::Tree::Funcall
    alias_method :__perform_sass_fn, :perform_sass_fn

    def perform_sass_fn(function, args, splat, environment)
      prof = Sass::Prof::Profiler.new(function.dup, :execute, args.dup,
        environment.dup)
      prof.start

      value = __perform_sass_fn(
        function, args, splat, environment)

      prof.stop

      value
    end
  end

  class Engine
    alias_method :__render, :render

    def render
      __render
    ensure
      Sass::Prof::Report.print_report
      Sass::Prof::Report.reset_report
    end
  end
end
