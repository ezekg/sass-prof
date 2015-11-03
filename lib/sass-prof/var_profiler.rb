module SassProf
  class VarProfiler < Profiler

    def initialize(subject, action, args = nil, env = nil)
      super subject, action, args, env
    end

    def name
      @subject
    end

    def args
      return nil if @args.nil?

      @args.inspect
    end

    def signature
      "#{Formatter.colorize("$#{name}", :blue)} = "\
      "#{Formatter.colorize(args, :purple)}"
    end
  end
end
