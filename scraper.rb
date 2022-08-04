# frozen_string_literal: true

require 'httparty'
require 'nokogiri'
require 'spreadsheet'

city = 'Samsun'

def request_url(address)
  response = HTTParty.get(address)
  html = response.body
  Nokogiri::HTML(html) # => Nokogiri::XML
end

def encoder(list)
  list.map { |info| info&.encode('UTF-16le', invalid: :replace, replace: '')&.encode('UTF-8') }
end

def column_check(db)
  init_headers = [:name, :"place types", :address, :coordinate, :phone,
                  :mail, :parking, :rating, :social, :website, :ophours]
  init_headers.map { |header| db[header] }
end

def header(table)
  [:name] + table.map { |row| row[0, row.index(':')].downcase.to_sym } + [:ophours]
end

def body(doc, table)
  content = table.map { |row| row[row.index(':') + 1, row.length] }
  ophours = [doc.xpath("//div[@class='five columns']/span").text.split(/(?=[A-Z])/).join(', ')]
  [doc.xpath('//h1/a/b').text] + content + ophours
end

def database(link)
  doc = request_url(link)
  table = doc.xpath('//tbody/tr').map(&:text)
  Hash[header(table).zip body(doc, table)]
end

def build_book
  workbook = Spreadsheet::Workbook.new
  sheet = workbook.create_worksheet name: 'places'
  sheet.row(0).concat %w[name type address coordinate phone mail parking rating social website ophours]
  index = 1

  { workbook: workbook, sheet: sheet, index: index }
end

def place_types(city)
  last_page = request_url("https://vymaps.com/TR/#{city}").xpath('//b[1]').text.split(' ')[-2].to_i
  types = []

  last_page.times do |page|
    types += request_url("https://vymaps.com/TR/#{city}/#{page + 1}").xpath('//div/a/@href').map(&:text)
  end
  types
end

def linker(city)
  book = build_book
  place_types(city).each do |type|
    url_stack(type, book)
  end
end

def url_stack(type, book)
  last_page = request_url(type).xpath('//div/b[1]').text.split(' ')[-2].to_i

  last_page.times do |page|
    links = request_url(type + (page + 1).to_s).xpath('//p/b/a/@href')
    book[:workbook].write 'places_samsun-deneme.xls'
    append_to_row(links, book)
  end
end

def append_to_row(links, book)
  links.each do |link|
    book[:sheet].row(book[:index]).concat encoder(column_check(database(link)))
    p book[:index] += 1
  end
end
linker(city)
