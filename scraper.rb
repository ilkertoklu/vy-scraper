# frozen_string_literal: true

require 'httparty'
require 'nokogiri'
require 'spreadsheet'

city = 'Samsun'

def request(adress)
  response = HTTParty.get(adress)
  html = response.body
  doc = Nokogiri::HTML(html)
end

def type(city)
  lastpage = request("https://vymaps.com/TR/#{city}").xpath('//b[1]').text.split(' ')[-2].to_i + 1
  types = []
  page = 1

  while page < lastpage
    url = "https://vymaps.com/TR/#{city}/#{page}"
    data = request(url).xpath('//div/a/@href')
    types += data
    page += 1
  end
  link(types)
end

def link(types)
  book = Spreadsheet::Workbook.new
  book.create_worksheet name: 'Places'
  sheet = book.worksheet(0)
  headers = %w(name type adress coordinate parking rating phone mail social website ophours)
  sheet.row(0).concat headers
  index = 1

  types.each do |type|
    lastpage = request(type).xpath('//div/b[1]').text.split(' ')[-2].to_i + 1
    page = 1

    while page < lastpage
      link_with_page = type.text + page.to_s
      doc = request(link_with_page)
      links = doc.xpath('//p/b/a/@href')
      page += 1

      links.each do |link|
        listing(link, book, sheet, index)
        index += 1
      end
    end
  end
end

def listing(link, book, sheet, index)
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
  encoded_list = []

  list.each do |element|
    encoded_list << element.encode('UTF-16le', invalid: :replace, replace: '').encode('UTF-8')
  end
  sheet.row(index).concat encoded_list
  book.write 'places.xls'
  puts index
end
type(city)
