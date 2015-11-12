module SassProf
  class ExtProfiler < Profiler

    def initialize(subject, action, args = nil, env = nil)
      super subject, action, args, env
    end

    def name
      @env.members.join(", ").tr "\n", ""
    end

    def args
      @subject.members.join ", "
    end

    def signature
      "#{Formatter.colorize(name, :blue)} < "\
      "#{Formatter.colorize(args, :purple)}"
    end
  end
end
