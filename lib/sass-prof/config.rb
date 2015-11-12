module SassProf
  module Config
    attr_accessor :t_max
    attr_accessor :max_width
    attr_accessor :output_file
    attr_accessor :quiet
    attr_accessor :color
    attr_accessor :precision
    attr_accessor :subtotal
    attr_accessor :ignore

    alias_method :max_execution_time=, :t_max=
    alias_method :max_execution_time,  :t_max
    alias_method :ignore_actions=,     :ignore=
    alias_method :ignore_actions,      :ignore

    @t_max       = 100
    @max_width   = false
    @output_file = false
    @quiet       = false
    @color       = true
    @precision   = 15
    @subtotal    = true
    @ignore      = []

    extend self
  end
end
