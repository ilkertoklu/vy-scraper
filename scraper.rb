# frozen_string_literal: true

require 'httparty'
require 'nokogiri'

city = 'Samsun'

def request(adress)
  response = HTTParty.get(adress)
  html = response.body
  doc = Nokogiri::HTML(html)
end

def listing(link)
  doc = request(link)
  name = doc.xpath('//h1/a/b').text
  type = doc.xpath('//tr[1]/td[3]').text
  adress = doc.xpath('//tr[2]/td[3]').text
  coordinate = doc.xpath('//tr[3]/td[3]/a').text
  parking = doc.xpath('//tr[6]/td[3]').text
  rating = doc.xpath('//tr[7]/td[3]').text
  phone = doc.xpath('//tr[4]/td[3]').text
  mail = doc.xpath('//tr[5]/td[3]').text
  social = doc.xpath('//tr[6]//@href').text
  social += doc.xpath('//tr[6]/td[3]/a').text
  website = doc.xpath('//tr[7]//@href').text
  website += doc.xpath('//tr[8]//@href').text
  ophours = doc.xpath("//div[@class='five columns']/span").text.split(/(?=[A-Z])/)
  ophours = ophours.join(', ')

  list = "#{name}\n#{type}\n#{adress}\n#{coordinate}\n#{parking}\n#{rating}\n#{phone}\n#{mail}\n#{social}\n#{website}\n#{ophours}\n\n"  
end

def type(city)
  types = []
  page = 1

  lastpage = request("https://vymaps.com/TR/#{city}").xpath('//b[1]').text.split(' ')[-2].to_i + 1
  puts "Looking for place types...\n"

  while page < lastpage
    url = "https://vymaps.com/TR/#{city}/#{page}"
    data = request(url).xpath('//div/a/@href')
    types += data
    page += 1
  end
  link(types)
end

def link(types)
  types.each do |type|
    lastpage = request(type).xpath('//div/b[1]').text.split(' ')[-2].to_i + 1
    page = 1

    while page < lastpage
      link_with_page = type.text + page.to_s
      doc = request(link_with_page)
      links = doc.xpath('//p/b/a/@href')
      page += 1

      links.each do |link|
        puts listing(link)
      end
    end
  end
end
type(city)
