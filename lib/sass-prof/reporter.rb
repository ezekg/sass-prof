module SassProf
  module Reporter
    attr_accessor :rows

    @rows = []

    def add_row(row)
      row = Formatter.truncate_row row if Config.max_width
      @rows << row
    end

    def reset_report
      @rows = []
    end

    def print_report
      log_report if Config.output_file
      puts Formatter.to_table @rows unless Config.quiet
    end

    def log_report
      File.open(Config.output_file, "a+") do |f|
        f.puts Formatter.to_table @rows.map { |r|
          r.map { |col| col.gsub Formatter::REGEX_ASCII, "" } }
      end
    end

    extend self
  end
end
