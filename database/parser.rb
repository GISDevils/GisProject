#!/usr/bin/ruby
# encoding: UTF-8

require 'bundler/setup'

require 'mysql'
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'json'

require_relative 'secrets'

def extract_unique_values(hash_array, key)
	values = Array.new
	hash_array.map do |hash|
		values << (Array.new << hash[key])
	end
	return values.flatten.uniq
end
 
def surround_values(values)
	surrounded_values = String.new
	values.each do |value|
		surrounded_values << ',' unless surrounded_values.empty?
		surrounded_values << '(' << value.inspect << ')'
	end
	return surrounded_values
end
 
def quote_values(values)
	quoted_values = String.new
	values.each do |value|
		quoted_values << ',' unless quoted_values.empty?
		quoted_values << value.inspect
	end
	return quoted_values
end

class PageParser
	def initialize(db, site)
		@db = db
		@site = site
	end

	def proceed()
		@site[:num].times do |i|
			page = Nokogiri::HTML(open(@site[:uri] % i))
			@places = @site[:parser].new.parse(page)

			self.insert_values(:cuisins, "cuisine_types")
			self.insert_values(:types, "cafe_types")
			self.insert_cafes
			self.insert_addresses
		
			self.associate_cafes
		end
	end

	protected
	def insert_values(key, table_name)
		values = extract_unique_values(@places, key)
		@db.query "INSERT IGNORE INTO #{table_name}(name) VALUES %s" % surround_values(values) unless values.empty?
	end

	def update_cafe_with(field, key, places_names)		
		ids = @db.query 'SELECT id FROM cafes WHERE name IN (%s) AND %s IS NULL' % [places_names, field]
		update_case = String.new
		ids.each_hash do |id|
			@places.select {|place| place[:id] == id['id']}.each do |place|
				next if place[key] == nil or place[key].empty?
				update_case << "WHEN #{place[:id]} THEN #{place[key].inspect} "
			end
		end
		@db.query "UPDATE cafes SET #{field} = CASE id " + update_case + "END" unless update_case.empty?
	end

	protected
	def insert_cafes()
		places_names = String.new
		@places.each do |place|
			places_names << ',' unless places_names.empty?
			places_names << '(' << place[:name].inspect << ')'
		end

		@db.query 'INSERT IGNORE INTO cafes(name) VALUES %s' % [places_names]
		ids = @db.query 'SELECT id, name FROM cafes WHERE (name) IN (%s)' % [places_names]
		ids.each_hash do |id|
			@places.select {|place| place[:name] == id['name']}.each do |place|
				place[:id] = id['id']
			end
		end

		self.update_cafe_with('phones', :phones, places_names)
		self.update_cafe_with('avg_price', :avg_price, places_names)
	end

	protected
	def insert_addresses()
		addresses = String.new
		@places.each do |place|
			next if place[:id] == nil or place[:street] == nil or place[:building] == nil
			addresses << ',' unless addresses.empty?
			addresses << '(' << place[:id].inspect << ',' << place[:street].inspect << ',' << place[:building].inspect << ')' 
		end
		@db.query "INSERT IGNORE INTO addresses (cafe_id, street, building) VALUES %s" % addresses unless addresses.empty?
	end

	protected
	def associate_cafes
		@places.each do |place|
			next if place[:id] == nil
			@db.query "INSERT IGNORE INTO cuisines SELECT %i, id FROM cuisine_types WHERE name IN (%s)" % [place[:id], quote_values(place[:cuisins])] unless place[:cuisins].empty?
			@db.query "INSERT IGNORE INTO types SELECT %i, id FROM cafe_types WHERE name IN (%s)" % [place[:id], quote_values(place[:types])] unless place[:types].empty?
		end
	end
end

class Resto74Parser
	def parse(data)
		page = data.css('div.text').text.tr("\t",'').split(/\n/).uniq
		places = Array.new
		page.each do |place|
			extract_place_data(places, place) 
		end
		return places
	end

	protected
	def extract_place_data(places, place_data)
		place_data.chomp!
		new_place = Hash.new

		name = place_data.scan(/(^[^,]+)/)[0]
		return if name == nil
		new_place[:name] = name[0].strip

		types = place_data.scan(/(?<=, )([\s\S]+)(?=Адрес:)/)[0]
		return if types == nil
		new_place[:types] = types[0].strip.downcase.split(', ')

		address = place_data.scan(/(?<=Адрес: )([\s\S]+)(?=Телефон:)/)[0]
		return if address == nil
		address_list = address[0].split(',')
		return if address_list.size < 2

		street = address_list[0]
		building = address_list[1].scan(/([0-9]+[a-zA-Zа-яА-Я\/]{0,2}+)/)[0]

		return if street == nil or building == nil
		new_place[:street] = street.strip
		new_place[:building] = building[0].strip

		phones_list = place_data.scan(/(?<=Телефон: )([\s\S]+)(?=Кухня:)/)[0]
		new_place[:phones] = (phones_list != nil) ? phones_list[0].gsub(':w', '').strip.downcase : nil

		cuisins_list = place_data.scan(/(?<=Кухня: )([A-Zа-я\,\s]*)/)[0]
		new_place[:cuisins] = (cuisins_list != nil) ? cuisins_list[0].strip.downcase.split(', ') : []

		new_place[:avg_price] = nil

		places << new_place
	end
end

class GobarsParser
	def parse(data)
		places = Array.new
		data.css('div.kb_text').each do |bar_data|
			extract_place_data(places, bar_data)
		end
		return places
	end

	protected
	def extract_place_data(places, place_data)
		new_place = Hash.new
		new_place[:name] = place_data.css('a').text

		blocks = place_data.css('p')
		size = blocks.size
		return if blocks == nil 

		types_id = 0
		address_id = 1
		phones_id = size - 1

		new_place[:types] = (types_id >= size) ? [] : blocks[types_id].text.downcase.strip.split(', ')

		address = (address_id >= size) ? "" : blocks[address_id].text.strip
		return if (address = address.scan(/(?<=\,)([\s\S]+)/)[0]) == nil or (address = address[0]) == nil
		return if (building = address.scan(/(?<=\,)([\S\s]+)/)[0]) == nil or (building = building[0].scan(/[0-9]+[a-zA-Zа-яА-Я\/]{0,2}+/)[0]) == nil

		new_place[:street] = address.scan(/(([\s\S][^\,])+)(?=\,)/)[0][0].strip
		new_place[:building] = building.strip.downcase

		new_place[:cuisins] = []

		phones = blocks[phones_id].css('span') unless phones_id >= size or phones_id <= address_id
		new_place[:phones] = (phones != nil and not phones.empty?) ? phones[0].text.downcase.strip : nil

		prices = place_data.text.downcase.strip.scan(/(?<=Счет\:)([\S\s]+)/)[0]
		prices = prices[0].scan(/[0-9]+/) unless prices == nil
		new_place[:avg_price] = (prices != nil) ? prices[0] : nil

		places << new_place
	end
end

def update_geolocations database
	uri = "http://maps.googleapis.com/maps/api/geocode/json?sensor=false&region=RU&address=%s"

	addresses = database.query 'SELECT cafe_id, street, building FROM addresses'

	addresses.each_hash do |address|
		cafe_id = address['cafe_id']
		street = address['street'].force_encoding("utf-8")
		building = address['building'].force_encoding("utf-8")

		rest_query = URI::escape(uri % "Chelyabinsk,#{street},#{building}")

		geodata = open rest_query 
		json = JSON.parse geodata.string

		next if json['status'] != 'OK'
		coords = json['results'][0]['geometry']['viewport']['northeast']

		longitude = coords['lng']
		latitude = coords['lat']

		database.query "UPDATE addresses SET longitude = #{longitude}, latitude = #{latitude} WHERE cafe_id = #{cafe_id} AND street = #{street.inspect} AND building = #{building.inspect}"
	end
end

begin
	sites = [
		{:uri => 'http://chel.gobars.ru/bars/page_%i.html', :num => 6, :parser => GobarsParser},
		{:uri => 'http://www.resto74.ru/items/%i', :num => 33, :parser => Resto74Parser},
	]

	db = Mysql.init
	db.options(Mysql::SET_CHARSET_NAME, 'utf8')
	db.real_connect('localhost', DB_USER, DB_PASSWORD, DB_NAME)

	sites.each do |site|
		parser = PageParser.new(db, site)
		parser.proceed
	end

	update_geolocations db
	db.close if db
end