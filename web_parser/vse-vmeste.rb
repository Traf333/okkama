require 'open-uri'
require 'nokogiri'

require_relative './parser'

def parse_details(details, regex)
  match = regex.match(details)
  match && match[1]&.strip
end

def adapter
  ->(page, _) do
    details = page.css(".single_news p").text
    {
      name: page.css("h2").text,
      phone: parse_details(details, /Телефон:(.+)/),
      email: parse_details(details, /Электронная почта:(.+)/),
      website: parse_details(details, /Сайт фонда:(.+)/),
      details: details.gsub("\r\n", " "),
      logo_src: "https://wse-wmeste.ru" + page.css(".single_news p img").first.attribute("src"),
    }
  end
end

def read_list
  Nokogiri::HTML(open("https://wse-wmeste.ru/about/talking/"), nil, Encoding::UTF_8.to_s)
end

page = read_list
urls = page.css("td p:first a").map { |f| f["href"] }.uniq

puts "Started #{Time.now}"

Parser.new("vse-vmeste", adapter: adapter).call(urls)

puts "Finished #{Time.now}"
