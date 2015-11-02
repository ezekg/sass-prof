module SassProf
  class Profiler
    attr_accessor :function
    attr_accessor :action
    attr_accessor :args
    attr_accessor :env

    def initialize(function, action, args = nil, env = nil)
      @function = function
      @action   = action
      @args     = args
      @env      = env
      @t_total  = 0
      @t_then   = 0
      @t_now    = 0
    end

    def start
      @t_then = Time.now
    end

    def stop
      @t_now = Time.now
      t_delta = (@t_now.to_f - @t_then.to_f) * 1000.0
      @t_then, @t_total = @t_now, t_delta

      create_fn_report
    end

    private

    def create_fn_report
      fn_report = [fn_source, fn_execution_time, fn_action,
        fn_signature]

      Reporter.add_row fn_report unless Config.quiet

      if @t_total > Config.t_max && is_performable_action?
        raise RuntimeError.new Formatter.colorize(
          "Max execution time of #{Config.t_max}ms reached for function"\
          " `#{fn_name}()` (took #{@t_total.round(3)}ms)", :red)
      end
    end

    def fn_execution_time
      color  = @t_total > Config.t_max ? :red : :green
      t_exec = "%.#{Config.precision}f" % @t_total
      Formatter.colorize t_exec, color
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
      return Formatter.colorize("Unknown file", :red) unless env

      orig_filename = env.options.fetch :original_filename, "Unknown file"
      filename      = env.options.fetch :filename, "Unknown file"

      Formatter.colorize "#{File.basename(orig_filename)}:"\
        "#{File.basename(filename)}", :yellow
    end

    def fn_action
      Formatter.colorize action, :yellow
    end

    def fn_signature
      "#{Formatter.colorize(fn_name, :blue)}"\
      "(#{Formatter.colorize(fn_args, :purple)})"
    end

    def is_performable_action?
      [:invoke, :include, :extend].include? action
    end
  end
end
