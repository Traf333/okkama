require 'active_support/core_ext/hash/conversions'
require 'open-uri'

require_relative './parser'

def adapter
  ->(page) do
    {
      location: page.css(".b-one-fund__info-str__place").text,
      name: page.css(".b-one-fund__head").text,
      website: page.css(".b-one-fund__logo a").attribute("href").value,
      details: page.css(".b-one-fund__txt").text.gsub("\n", " "),
      logo_src: page.css(".b-one-fund__logo img").attribute("src"),
    }
  end
end

#
hash = Hash.from_xml(open("https://nuzhnapomosh.ru/np_sitemaps/sitemap_funds.xml"))
urls = hash["urlset"]["url"].map { |f| f["loc"] }

puts "Started #{Time.now}"

Parser.new("nuzhnapomosh", adapter: adapter).call(urls)

puts "Finished #{Time.now}"
