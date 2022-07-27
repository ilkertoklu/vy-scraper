# frozen_string_literal: true

require 'httparty'
require 'nokogiri'
require 'spreadsheet'

city = 'Samsun' #Change as where you wish to scrap, or request the cities and countries array.

def request(adress)
  response = HTTParty.get(adress)
  html = response.body
  Nokogiri::HTML(html)
end

def encoder(list)
  list.map { |info| info.encode('UTF-16le', invalid: :replace, replace: '').encode('UTF-8') unless info.nil? }
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
        wb.write 'places_samsun-deneme.xls'
        p index += 1
      end
    end
  end
end

def listing(link, sheet, index)
  doc = request(link)
  table = doc.xpath('//tbody/tr').map(&:text)
  headers = [:name] + table.map { |row| row[0, row.index(':')].downcase.to_sym } + [:ophours]

  content = table.map { |row| row[row.index(':') + 1, row.length] }
  ophours = [doc.xpath("//div[@class='five columns']/span").text.split(/(?=[A-Z])/).join(', ')]
  body = [doc.xpath('//h1/a/b').text] + content + ophours
  db = Hash[headers.zip body]

  init_headers = [:name, :"place types", :address, :coordinate, :phone,
                  :mail, :parking, :rating, :social, :website, :ophours]
  data = []

  init_headers.each { |header| data << db[header] }
  sheet.row(index).concat encoder(data)
end
type(city)
