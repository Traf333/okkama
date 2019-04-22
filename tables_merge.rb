require 'roo'
require 'csv'

xlsx = Roo::Spreadsheet.open("./build/founds.xlsx")
sheets = {}
4.times do |i|
  data = []
  sheet = xlsx.sheet(i)
  header = sheet.row(1)
  headers.concat(header)
  (2..sheet.last_row).each do |row_i|
    data << Hash[header.zip(sheet.row(row_i))]
  end
  sheets[i] = data
end

hh = headers.uniq

result = sheets[0]

def prepare(str)
  str.downcase.gsub(/[^[:word:]]/, "")
end
(1..3).each do |i|
  sheet = sheets[i]

  sheet.each do |item|
    r = result.find { |r| prepare(r["name"]).include?(prepare(item["name"])) }
    if r
      hh.each { |k| r[k] = r[k] || item[k] }
    else
      result << item
    end
  end
end


CSV.open("build/#{Date.today}/merged_funds.csv", "w", col_sep: "|") do |csv|
  csv << hh
  result.each do |row|
    csv << hh.map { |c| row[c] }
  end
end
