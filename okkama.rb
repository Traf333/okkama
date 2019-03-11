require 'csv'

class Okkama
  HEADERS = ["email", "name", "amount", "currency", "donated_at", "target", "type", "match_type"]

  attr_reader :source, :report, :namespace

  def initialize(*args)
    @source = CSV.read(args[0], col_sep: ";")
    @report = CSV.read(args[1], col_sep: ";")
    @namespace = "build/#{Date.today}/#{args[1].split('/').last}"
  end

  def transactions
    @transactions ||= source[1..-1].map do |t|
      Transaction.new(*cleared(t))
    end.sort_by(&:donated_at)
  end

  def report_items
    h = Header.new(report.first)
    @report_items ||= report[1..-1].map do |t|
      Source.new(t[h.email].to_s, t[h.name].to_s)
    end.compact
  end

  def build
    result = []
    report_items.each do |item|
      found = item.in(transactions)
      if found.any?
        found.first.match_type = "matched"
        found[1..-1].each {|c| c.match_type = "repeated" }
        result.concat(found)
      else
        item.match_type = "not matched"
        result << item
      end
    end

    write_file(result)
  end

  # private

  def write_file(result)
    CSV.open(namespace, "w", encoding: "windows-1251:utf-8", col_sep: ";") do |csv|
      csv << HEADERS
      result.each do |transaction|
        csv << transaction.to_a
      end
    end
  end

  def cleared(row)
    h = Header.new(source.first)
    [
      row[h.email].to_s,
      row[h.name].to_s,
      row[h.amount],
      row[h.currency],
      DateTime.parse(row[h.donated_at]).strftime("%F %H:%M"),
      row[h.target],
      row[h.type].to_s
    ]
  end

  Source = Struct.new(:email, :name, :status, :match_type) do

    def email_prefix
      email.to_s.split("@").first.to_s
    end

    def in(transactions)
      transactions.select { |transaction| transaction.valid? && match?(transaction) }
    end

    def match?(transaction)
      return true if !email_prefix.empty? && transaction.email_prefix == email_prefix
      return true if !name.empty? && transaction.name == name

      return false
    end

    def to_a
      HEADERS.map do |d|
        self.respond_to?(d) ? self.send(d) : ""
      end
    end
  end

  Transaction = Struct.new(:email, :name, :amount, :currency, :donated_at, :target, :type, :match_type) do
    def email_prefix
      email.to_s.split("@").first.to_s
    end

    def valid?
      ["Оплата", "Оплата с созданием подписки"].include?(type) && !name.include?("MOMENTUM")
    end

    def to_a
      HEADERS.map { |d| self.send(d) }
    end
  end

  Header = Struct.new(:fields) do

    def name
      fields.index { |str| str.match(/name|имя/i) }
    end

    def email
      fields.index { |str| str.match(/mail/i) }
    end

    def amount
      fields.index { |str| str.match(/сумма/i) }
    end

    def currency
      fields.index { |str| str.match(/валюта/i) }
    end

    def donated_at
      fields.index { |str| str.match(/дата/i) }
    end

    def target
      fields.index { |str| str.match(/назначение/i) }
    end

    def type
      fields.index { |str| str.match(/тип/i) }
    end

    def status
      fields.index { |str| str.match(/status/i) }
    end
  end
end
