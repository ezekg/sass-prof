module SassProf
  class ExtProfiler < Profiler

    def initialize(subject, action, args = nil, env = nil)
      super subject, action, args, env
    end

    def name
      @subject.join ", "
    end

    def args
      "{ ... }"
    end

    def signature
      "#{Formatter.colorize(name, :blue)} "\
      "#{Formatter.colorize(args, :purple)}"
    end
  end
end
