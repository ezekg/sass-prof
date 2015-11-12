module SassProf
  module Timer

    SUMMARIES = [
      :t_total,
      # :m_total,
      :t_var_total,
      :cnt_var_total,
      :cnt_var_global_total,
      :cnt_var_local_total,
      :t_fundef_total,
      :cnt_fundef_total,
      :t_fun_total,
      :cnt_fun_total,
      :t_mixdef_total,
      :cnt_mixdef_total,
      :t_mix_total,
      :cnt_mix_total,
      # :t_ext_total,
      # :cnt_ext_total,
    ]

    class << self
      SUMMARIES.each do |summary|
        instance_variable_set "@#{summary}", 0

        define_method "add_#{summary}" do |value|
          prev = instance_variable_get("@#{summary}") || 0
          instance_variable_set("@#{summary}", prev + value)
        end

        define_method "#{summary}" do
          instance_variable_get("@#{summary}")
        end
      end
    end
  end
end
