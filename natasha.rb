require 'rubyXL'

def cleared(row)
  [row[14]&.value, row[15]&.value, row[8].value, row[1].value.strftime("%F"), row[19].value, row[10]&.value]
end

Source = Struct.new(:name, :email, :status) do
  def valid?
    status == "Был переход по ссылке"
  end

  def name
    self.name == "MOMENTUM" ? nil : self.name
  end
end

Transaction = Struct.new(:name, :email, :type, :status, :sum, :donated_at, :target) do
  def email_prefix
    email.to_s.split("@").first
  end

  def valid?
    ["Оплата", "Оплата с созданием подписки"].include?(type)
  end
end

headers = ["email", "name", "sum", "donated_at", "target", "type"]

# Okkama
class ReportBuilder

  attr_reader :source, :report, :found, :not_found, :track

  def initialize(*args)
    @source = read_file(args[0])
    @report = read_file(args[1])
  end

  def transactions
    @transactions ||= rows(source).map do |t|
      Transaction.new(*cleared(t))
    end
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
    emails, names = rows(report).map do |row|
      email = row[0].value.to_s
      name = row[5].value
      status = row[-1].value
      [email.split("@").first, name] if status == "Был переход по ссылке"
    end.compact.transpose

    rows(source).map do |row|
      type = row[10].value
      status = row[20].value

      next if status != "Завершена"


      if valid_type?(type) && match?(row, emails, names)
        found << row
      else
        not_found << row
      end
    end

    write_file
  end

  private

  def header(collection)
    collection.sheet_data[0].map(&:value)
  end

  def rows(collection)
    collection.sheet_data[1..-1]
  end

  def match?(row, emails, names)
    email = row[14]&.value.to_s
    name = row[15]&.value

    return false if name.include?("MOMENTUM")

    emails.compact.include?(email.split("@").first) || names.compact.include?(name)
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
    headers = ["email", "name", "sum", "donated_at", "target", "type"]

    headers.each_with_index do |name, index|
      worksheet.add_cell(0, index, name)
      worksheet.change_column_width(index, 22)
    end
    rows.each_with_index do |row, index|
      cleared(row).each_with_index { |value, cell_idx| worksheet.add_cell(index + 1, cell_idx, value) }
    end
  end

  def valid_type?(type)
    ["Оплата", "Оплата с созданием подписки"].include?(type)
  end

  def cleared(row)
    [row[14]&.value, row[15]&.value, row[8].value, row[1].value.strftime("%F"), row[19].value, row[10]&.value]
  end


  # todo: check percentage for name matching
  def string_difference_percent(a, b)
    longer = [a.size, b.size].max
    same = a.each_char.zip(b.each_char).select { |a, b| a == b }.size
    (longer - same) / a.size.to_f
  end
end

# r = ReportBuilder.new("/Users/jorik/projects/source-sheet.xlsx", "/Users/jorik/some.xlsx")
r = ReportBuilder.new("/Users/jorik/Downloads/Transactions\ \(1\)\ с08-19.xlsx", "/Users/jorik/report.xlsx")
r.build
