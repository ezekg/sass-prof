module SassProf
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
end
