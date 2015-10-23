# encoding: UTF-8

require "terminal-table"

module Sass
  module Prof

    module Config
      attr_accessor :t_max
      attr_accessor :max_width
      attr_accessor :output_file
      attr_accessor :quiet
      attr_accessor :color
      attr_accessor :precision

      alias_method :max_execution_time=, :t_max=
      alias_method :max_execution_time,  :t_max

      @t_max       = 100
      @max_width   = false
      @output_file = false
      @quiet       = false
      @color       = true
      @precision   = 15

      extend self
    end

    module Report
      attr_accessor :rows

      @rows = []

      def add_row(row)
        row = Prof::Formatter.truncate_row row if Prof::Config.max_width
        @rows << row
      end

      def reset_report
        @rows = []
      end

      def print_report
        log_report if Prof::Config.output_file
        puts Prof::Formatter.to_table @rows
      end

      def log_report
        File.open(Prof::Config.output_file, "a+") do |f|
          f.puts Prof::Formatter.to_table @rows.map { |r|
            r.map { |col| col.gsub /\e\[(\d+)(;\d+)*m/, "" } }
        end
      end

      extend self
    end

    module Formatter

      COLORS = Hash.new("37").merge({
        :black  => "30",
        :red    => "31",
        :green  => "32",
        :yellow => "33",
        :blue   => "34",
        :purple => "35",
        :cyan   => "36",
        :white  => "37",
      })

      def colorize(string, color)
        return string.to_s unless Prof::Config.color

        "\e[0;#{COLORS.fetch(color)}m#{string}\e[0m"
      end

      def to_table(rows)
        pr = Prof::Config.precision / 3 - 5 # 5 is to account for whitespace
        t  = Time.now.to_f

        t_ms = rows.map { |c|
          t += c[1].gsub(/\e\[(\d+)(;\d+)*m/, "").to_f }

        t -= Time.now.to_f

        ss, ms = t.divmod 1000
        mm, ss = ss.divmod 60
        # hh, mm = mm.divmod 60

        # Add total execution time footer
        rows << :separator
        rows << ["Total", "%.#{pr}fm %.#{pr}fs %.#{pr}fms" % [mm, ss, ms]]

        table = Terminal::Table.new({
          :headings => ["File", "Execution Time", "Action", "Signature"],
          :rows     => rows
        })

        table
      end

      def truncate_row(row)
        max_width = Prof::Config.max_width
        tr_row = []

        row.map do |col|
          clean_width = col.gsub(/\e\[(\d+)(;\d+)*m/, "").length
          diff        = col.length - clean_width

          if clean_width > max_width
            tr_row << (col[0..max_width + diff] << "\e[0m...")
          else
            tr_row << col
          end
        end

        tr_row
      end

      extend self
    end

    class Profiler
      attr_accessor :function, :action, :args, :env

      @@t_total = 0
      @@t_then  = 0
      @@t_now   = 0

      def initialize(function, action, args = nil, env = nil)
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

        create_fn_report
      end

      private

      def create_fn_report
        fn_report = [fn_source, fn_execution_time, fn_action,
          fn_signature]

        Prof::Report.add_row fn_report unless Prof::Config.quiet

        if @@t_total > Prof::Config.t_max && action == :execute
          raise RuntimeError.new Prof::Formatter.colorize(
            "Max execution time of #{Prof::Config.t_max}ms reached for function"\
            " `#{fn_name}()` (took #{@@t_total.round(3)}ms)", :red)
        end
      end

      def fn_execution_time
        color  = @@t_total > Prof::Config.t_max ? :red : :green
        t_exec = "%.#{Prof::Config.precision}f" % @@t_total
        Prof::Formatter.colorize t_exec, color
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
        return Prof::Formatter.colorize("Unknown file", :red) unless env

        orig_filename = env.options.fetch :original_filename, "Unknown file"
        filename      = env.options.fetch :filename, "Unknown file"

        Prof::Formatter.colorize "#{File.basename(orig_filename)}:"\
          "#{File.basename(filename)}", :yellow
      end

      def fn_action
        Prof::Formatter.colorize action.capitalize, :yellow
      end

      def fn_signature
        "#{Prof::Formatter.colorize(fn_name, :blue)}"\
        "(#{Prof::Formatter.colorize(fn_args, :purple)})"
      end
    end
  end

  # Monkey patch Sass to utilize Profiler
  class Tree::Visitors::Perform
    alias_method :__visit_function, :visit_function

    def visit_function(node)
      prof = Prof::Profiler.new(node.dup, :allocate)
      prof.start

      value = __visit_function node

      prof.stop

      value
    end
  end

  class Script::Tree::Funcall
    alias_method :__perform_sass_fn, :perform_sass_fn

    def perform_sass_fn(function, args, splat, environment)
      prof = Prof::Profiler.new(function.dup, :execute, args.dup,
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
