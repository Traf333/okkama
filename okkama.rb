require 'rubyXL'

class Okkama
  HEADERS = ["email", "name", "sum", "donated_at", "target", "type", "match_type"]

  attr_reader :source, :report, :found, :not_found, :track

  def initialize(*args)
    @source = read_file(args[0])
    @report = read_file(args[1])
  end

  def transactions
    @transactions ||= rows(source).map do |t|
      Transaction.new(*cleared(t))
    end.sort_by(&:donated_at)
  end

  def report_items
    @report_items ||= rows(report).map do |t|
      next if t[-1].value != "Был переход по ссылке"

      Source.new(t[0]&.value.to_s, t[5]&.value.to_s)
    end.compact
  end

  def build
    @found = []
    @not_found = []
    @track = []

    transactions.each do |t|
      if t.in?(report_items)
        if found.any? { |tr| t.match?(tr) }
          t.match_type = "repeated"
        else
          t.match_type = "matched"
        end
        found << t
      else
        not_found << t
      end
    end

    write_file
  end

  # private

  def header(collection)
    collection.sheet_data[0].map(&:value)
  end

  def rows(collection)
    collection.sheet_data[1..-1]
  end

  def read_file(path)
    RubyXL::Parser.parse(path).worksheets[0]
  end

  def write_file
    workbook = RubyXL::Workbook.new
    matched_sheet = workbook.worksheets[0]
    matched_sheet.sheet_name = "Matched users"
    not_matched_sheet = workbook.add_worksheet("Not matched users")

    write_sheet(matched_sheet, found)
    write_sheet(not_matched_sheet, not_found)

    workbook.write("/Users/jorik/report-#{Date.today.to_s}.xlsx")
  end

  def write_sheet(worksheet, rows)

    HEADERS.each_with_index do |name, index|
      worksheet.add_cell(0, index, name)
      worksheet.change_column_width(index, 22)
    end
    rows.each_with_index do |row, index|
      HEADERS.each_with_index do |value, cell_idx|
        worksheet.add_cell(index + 1, cell_idx, row.send(value))
      end
    end
  end

  def cleared(row)
    [row[14]&.value.to_s, row[15]&.value.to_s, row[8].value, row[1].value.strftime("%F"), row[19].value, row[10]&.value.to_s]
  end

  Source = Struct.new(:email, :name, :status) do

    def email_prefix
      email.to_s.split("@").first.to_s
    end
  end

  Transaction = Struct.new(:email, :name, :sum, :donated_at, :target, :type, :match_type) do
    def email_prefix
      email.to_s.split("@").first.to_s
    end

    def valid?
      ["Оплата", "Оплата с созданием подписки"].include?(type) && !name.include?("MOMENTUM")
    end

    def in?(items)
      items.any? { |item| valid? && match?(item) }
    end

    def match?(item)
      return true if !email_prefix.empty? && item.email_prefix == email_prefix
      return true if !name.empty? && item.name == name

      return false
    end
  end

  #
  # # todo: check percentage for name matching
  # def string_difference_percent(a, b)
  #   longer = [a.size, b.size].max
  #   same = a.each_char.zip(b.each_char).select { |a, b| a == b }.size
  #   (longer - same) / a.size.to_f
  # end
end

# r = ReportBuilder.new("/Users/jorik/projects/source-sheet.xlsx", "/Users/jorik/some.xlsx")
r = Okkama.new("/Users/jorik/Downloads/Transactions\ \(1\)\ с08-19.xlsx", "/Users/jorik/report.xlsx")
r.build
