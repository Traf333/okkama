require 'active_support/core_ext/hash/conversions'
require 'open-uri'

require_relative './parser'

def adapter
  ->(page) do
    phone_el = page.css(".p-fund-detail__info-row").find { |el| el.text.include? "Телефон" }
    website_el = page.css(".p-fund-detail__info-row").find { |el| el.text.include? "Сайт" }
    {
      location: page.css(".breadcrumbs span.link__text").text,
      name: page.css(".hdr__inner")[0].text,
      phone: phone_el ? phone_el.text.gsub("Телефон", "") : "",
      website: website_el ? website_el.text.gsub("Сайт", "") : "",
      details: page.css(".cols__inner p").text.gsub("\r\n", " "),
      logo_src: "https://dobro.mail.ru" + page.css(".photo__pic").attribute("src"),
    }
  end
end

#
hash = Hash.from_xml(open("https://dobro.mail.ru/sitemap-funds.xml"))
urls = hash["urlset"]["url"].map { |f| f["loc"] }

puts "Started #{Time.now}"

Parser.new("dobro", adapter: adapter).call(urls)

puts "Finished #{Time.now}"
