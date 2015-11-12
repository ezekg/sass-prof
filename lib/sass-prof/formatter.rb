module SassProf
  module Formatter

    REGEX_ASCII = /\e\[(\d+)(;\d+)*m/
    COLORS      = Hash.new("37").merge({
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
      return string.to_s unless Config.color

      "\e[0;#{COLORS.fetch(color)}m#{string}\e[0m"
    end

    def to_table(rows)
      t_ms = Timer.t_total

      return if t_ms.nil?

      t_ss, t_ms = t_ms.divmod 1000
      t_mm, t_ss = t_ss.divmod 60

      # Add summary for each action type
      Timer::SUMMARIES.reject { |s| s == :t_total }.each do |summary|
        break unless Config.subtotal

        case summary
        when /^(t_)/
          sum_t_ms = Timer.send summary

          next if sum_t_ms.nil?

          sum_t_ss, sum_t_ms = sum_t_ms.divmod 1000
          sum_t_mm, sum_t_ss = sum_t_ss.divmod 60

          rows << :separator
          rows << [
            "subtotal",
            "%.0fm %.0fs %.0fms" % [sum_t_mm, sum_t_ss, sum_t_ms],
            "#{summary}".gsub(/(^(t_)|(_total)$)/, ""),
            ""
          ]
        when /^(cnt_)/
          count = Timer.send summary

          next if count.nil?

          rows << :separator
          rows << [
            "count",
            "#{count}",
            "#{summary}".gsub(/(^(cnt_)|(_total)$)/, ""),
            ""
          ]
        end
      end

      # Add footer containing total execution time
      rows << :separator
      rows << [
        "total",
        "%.0fm %.0fs %.0fms" % [t_mm, t_ss, t_ms],
        "all",
        ""
      ]

      table = Terminal::Table.new({
        :headings => ["file", "execution time", "action", "signature"],
        :rows     => rows
      })

      table
    end

    def truncate_row(row)
      max_width = Config.max_width
      tr_row = []

      row.map do |col|
        clean_width = col.gsub(REGEX_ASCII, "").length
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
end
