module SassProf
  class ExtProfiler < Profiler

    def initialize(subject, action, args = nil, env = nil)
      super subject, action, args, env
    end

    def name
      @env.selector.members.join(", ").tr "\n", ""
    end

    def args
      @subject.selector.join ", "
    end

    def signature
      "#{Formatter.colorize(name, :blue)} < "\
      "#{Formatter.colorize(args, :purple)}"
    end
  end
end
