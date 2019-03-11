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
    found = []
    transactions.each do |t|
      if t.in?(report_items)
        t.match_type = found.any? { |tr| t.match?(tr) } ? "repeated" : "matched"
        found << t
      else
        t.match_type = "not matched"
      end
    end

    write_file
  end

  # private

  def write_file
    CSV.open(namespace, "w") do |csv|
      csv << HEADERS
      transactions.each do |transaction|
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
      DateTime.parse(row[h.donated_at]).strftime("%F"),
      row[h.target],
      row[h.type].to_s
    ]
  end

  Source = Struct.new(:email, :name, :status) do

    def email_prefix
      email.to_s.split("@").first.to_s
    end
  end

  Transaction = Struct.new(:email, :name, :amount, :currency, :donated_at, :target, :type, :match_type) do
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
