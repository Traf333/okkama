require 'nokogiri'
require 'open-uri'
require 'csv'

class Parser
  HEADER = %w[name location phone website email logo_src details tags legal_form address]

  attr_reader :website, :adapter, :records

  def initialize(website, adapter:, records: [])
    @website = website
    @adapter = adapter
    @records = records
  end

  def call(urls)
    founds = []

    urls.each do |url|
      begin
        founds << parse(read_page(url))
      rescue
        puts "error with #{url}"
      end
    end

    write_file(founds)
  end

  private

  def write_file(founds)
    CSV.open("build/#{website}.csv", "w", col_sep: "|") do |csv|
      csv << HEADER
      founds.each do |found|
        csv << HEADER.map { |f| found[f.to_sym] }
      end
    end
  end

  def read_page(url)
    Nokogiri::HTML(open(url), nil, Encoding::UTF_8.to_s)
  end

  def parse(page)
    adapter.call(page, records)
  end
end
