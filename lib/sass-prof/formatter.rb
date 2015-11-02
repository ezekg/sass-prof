module SassProf
  module Formatter

    COLORS = Hash.new("37").merge({
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
      pr   = Config.precision / 3 - 5 # 5 is to account for whitespace
      t_ms = rows.map { |c|
        c[1].gsub(/\e\[(\d+)(;\d+)*m/, "").to_f }.reduce :+

      return if t_ms.nil?

      t_ss, t_ms = t_ms.divmod 1000
      t_mm, t_ss = t_ss.divmod 60

      # Add total execution time footer
      rows << :separator
      rows << [
        "total",
        "%.#{pr}fm %.#{pr}fs %.#{pr}fms" % [t_mm, t_ss, t_ms],
        "",
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
        clean_width = col.gsub(/\e\[(\d+)(;\d+)*m/, "").length
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
