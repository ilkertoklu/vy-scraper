# frozen_string_literal: true

require 'httparty'
require 'nokogiri'
require 'spreadsheet'

city = 'Samsun'

def request(adress)
  response = HTTParty.get(adress)
  html = response.body
  Nokogiri::HTML(html)
end

def encoder(list)
  list.map { |info| info.encode('UTF-16le', invalid: :replace, replace: '').encode('UTF-8') }
end

def type(city)
  last_page = request("https://vymaps.com/TR/#{city}").xpath('//b[1]').text.split(' ')[-2].to_i + 1
  types = []
  page = 1

  while page < last_page
    url = "https://vymaps.com/TR/#{city}/#{page}"
    data = request(url).xpath('//div/a/@href')
    types += data
    page += 1
  end
  link(types)
end

def link(types)
  wb = Spreadsheet::Workbook.new
  sheet = wb.create_worksheet name: 'places'
  sheet.row(0).concat %w[name type adress coordinate parking rating phone mail social website ophours]
  index = 1

  types.each do |type|
    last_page = request(type).xpath('//div/b[1]').text.split(' ')[-2].to_i + 1
    page = 1

    while page < last_page
      link_with_page = type.text + page.to_s
      links = request(link_with_page).xpath('//p/b/a/@href')
      page += 1

      links.each do |link|
        listing(link, sheet, index)
        wb.write 'samsun_places.xls'
        p index += 1
      end
    end
  end
end

def listing(link, sheet, index)
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

  list = name, type, adress, coordinate, parking, rating, phone, mail, social, website, ophours
  sheet.row(index).concat encoder(list)
end
type(city)
