require 'active_support/core_ext/hash/conversions'
require 'open-uri'
require 'httparty'

require_relative './parser'

def adapter
  ->(page, records) do
    record = records.find { |f| f["title"].strip == page.css("h1").text.strip }
    contacts = page.css(".nko-contacts").text
    {
      location: tos(record["city"]),
      name: tos(record["title"]),
      phone: tos(contacts.scan(/Тел.*/).first),
      website: tos(contacts.scan(/Сайт.*/).first),
      email: tos(contacts.scan(/\S*@.*/).first),
      address: tos(contacts.scan(/ул.*/).first),
      details: record["description"].gsub("\r\n", " "),
      tags: record["topics"].map { |v| v["title"] }.join(", "),
      legal_form: tos(record["legal_form"])
    }
  end
end

def tos(str)
  str.to_s.strip.gsub("\n", "")
end


def obtain
  data = []
  i = 1
  loop do
    q = HTTParty.get("https://blago.ru/companies", query: { page: i }, :headers => { 'Content-Type' => 'application/json', 'X-Requested-With' => 'XMLHttpRequest' })
    data.concat q["items"]["data"]
    break if q["items"]["current_page"] == q["items"]["last_page"]
    i += 1
  end

  data
end

puts "Started #{Time.now}"

records = obtain
urls = records.map { |f| "https://blago.ru/companies/view/" + f["id"].to_s }
Parser.new("blago", adapter: adapter, records: records).call(urls)

puts "Finished #{Time.now}"

