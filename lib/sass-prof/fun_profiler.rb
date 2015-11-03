module SassProf
  class FunProfiler < Profiler

    def initialize(subject, action, args = nil, env = nil)
      super subject, action, args, env
    end
  end
end
