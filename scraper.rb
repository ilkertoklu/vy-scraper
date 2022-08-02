# frozen_string_literal: true

require 'httparty'
require 'nokogiri'
require 'spreadsheet'

city = 'Samsun' # Change as where you wish to scrap, or request the cities and countries array.

def request(adress)
  response = HTTParty.get(adress)
  html = response.body
  Nokogiri::HTML(html)
end

def encoder(list)
  list.map do |info|
    info.encode('UTF-16le', invalid: :replace, replace: '').encode('UTF-8') unless info.nil? || info.empty?
  end
end

def column_check(db)
  init_headers = [:name, :"place types", :address, :coordinate, :phone,
                  :mail, :parking, :rating, :social, :website, :ophours]
  data = []
  init_headers.each { |header| data << db[header] }
  data
end

def database(link)
  doc = request(link)
  table = doc.xpath('//tbody/tr').map(&:text)
  headers = [:name] + table.map { |row| row[0, row.index(':')].downcase.to_sym } + [:ophours]

  content = table.map { |row| row[row.index(':') + 1, row.length] }
  ophours = [doc.xpath("//div[@class='five columns']/span").text.split(/(?=[A-Z])/).join(', ')]
  body = [doc.xpath('//h1/a/b').text] + content + ophours
  Hash[headers.zip body]
end

def type(city)
  last_page = request("https://vymaps.com/TR/#{city}").xpath('//b[1]').text.split(' ')[-2].to_i + 1
  page = 1
  types = []

  while page < last_page
    types += request("https://vymaps.com/TR/#{city}/#{page}").xpath('//div/a/@href')
    page += 1
  end
  types
end

def book_builder
  workbook = Spreadsheet::Workbook.new
  sheet = workbook.create_worksheet name: 'places'
  sheet.row(0).concat %w[name type address coordinate phone mail parking rating social website ophours]
  index = 1

  { workbook: workbook, sheet: sheet, index: index }
end

def link(city)
  book = book_builder
  type(city).each do |type|
    last_page = request(type).xpath('//div/b[1]').text.split(' ')[-2].to_i + 1
    page = 1
    stack(page, last_page, type, book)
  end
end

def stack(page, last_page, type, book)
  while page < last_page
    links = request(type.text + page.to_s).xpath('//p/b/a/@href')
    book[:workbook].write 'places_samsun-deneme-pg.xls'
    append(links, book)
    page += 1
  end
end

def append(links, book)
  links.each do |link|
    book[:sheet].row(book[:index]).concat encoder(column_check(database(link)))
    p book[:index] += 1
  end
end
link(city)
