#!/usr/bin/ruby
# encoding: UTF-8

require 'bundler/setup'

require 'mysql'
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'json'
require 'unicode'

require_relative 'secrets'

def extract_unique_values hash_array, key
	values = Array.new
	hash_array.map do |hash|
		values << (Array.new << hash[key])
	end
	return values.flatten.uniq
end
 
def surround_values values
	surrounded_values = String.new
	values.each do |value|
		surrounded_values << ',' unless surrounded_values.empty?
		surrounded_values << '(' << value.inspect << ')'
	end
	return surrounded_values
end
 
def quote_values values
	quoted_values = String.new
	values.each do |value|
		quoted_values << ',' unless quoted_values.empty?
		quoted_values << value.inspect
	end
	return quoted_values
end

class PageParser
	def initialize db, site
		@db = db
		@site = site
	end

	def proceed
		begin
			@site[:num].times do |i|
				page = Nokogiri::HTML(open(@site[:uri] % i))
				@places = @site[:parser].new.parse(page)

				self.insert_values(:cuisins, "cuisine_types")
				self.insert_cafes
				self.insert_addresses
			
				self.associate_cafes
			end
		rescue OpenURI::HTTPError => e
			puts e.message
			puts e.backtrace
		end
	end

	protected
	def insert_values key, table_name
		values = extract_unique_values(@places, key)
		@db.query "INSERT IGNORE INTO #{table_name}(name) VALUES %s" % surround_values(values) unless values.empty?
	end

	@@types = {
		"ресторан" => 1,
		"кафе" => 2,
		"бар" => 3,
		"суши" => 4,
		"доставка" => 7,
		"пиццерия" => 5,
		"café" => 2,
		"bar" => 3,
		"караоке" => 6,
		"restaurant" => 1,
		"паб" => 8,
		"кофе" => 9,
		"cafe" => 2,
		"банкет" => 10,
		"ночной клуб" => 11,
		"бильярд" => 12,
		"комплекс" => 13,
		"пирог" => 14,
		"трактир" => 8,
		"кондитерск" => 15,
		"пекарн" => 15,
		"karaoke" => 6,
		"дайнер" => 1,
		"стейк" => 1,
		"боулинг" => 16,
		"зал" => 10,
		"клуб" => 3,
		"кулинар" => 15
	}

	protected 
	def get_type_id new_type
		result = Array.new
		@@types.each do |type, id|
			result << id unless Unicode::downcase(new_type).index(type).nil? or id.nil?
		end
		puts new_type if result.empty?
		return result
	end

	protected
	def insert_cafes
		places_names = String.new
		places_values = String.new
		@places.each do |place|
			places_names << ',' unless places_names.empty?
			places_values << ',' unless places_values.empty?

			name = place[:name]
			phones = place[:phones]
			avg_price = place[:avg_price]

			places_names << '(' << name.inspect << ')'
			places_values << '(' << name.inspect << ',' << (phones.nil? ? 'NULL' : phones.inspect)  << ',' << (avg_price.nil? ? 'NULL' : avg_price) << ')'
		end 

		@db.query 'INSERT INTO cafes(name, phones, avg_price) VALUES %s ON DUPLICATE KEY UPDATE phones = COALESCE(cafes.phones, VALUES(phones)), avg_price = COALESCE(cafes.avg_price, VALUES(avg_price))' % [places_values]
		ids = @db.query 'SELECT id, name FROM cafes WHERE (name) IN (%s)' % [places_names]
		ids.each_hash do |id|
			@places.select {|place| place[:name] == id['name'].force_encoding('utf-8')}.each do |place|
				place[:id] = id['id']
			end
		end
	end

	protected
	def insert_addresses
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
		types = String.new
		@places.each do |place|
			next if place[:id] == nil
			@db.query "INSERT IGNORE INTO cuisines SELECT %i, id FROM cuisine_types WHERE name IN (%s)" % [place[:id], quote_values(place[:cuisins])] unless place[:cuisins].empty?

			place[:types].each do |type|
				type_id = get_type_id type
				place[:types_ids].concat type_id unless type_id.nil?
			end

			place[:types_ids].each do |type_id|
				types << ',' unless types.empty?
				types << '(' << place[:id] << ',' << type_id.to_s << ')'
			end
		end
		@db.query "INSERT IGNORE INTO types VALUES %s" % [types] unless types.empty?
	end
end

class Resto74Parser
	def parse data
		page = data.css('div.text').text.tr("\t",'').split(/\n/).uniq
		places = Array.new
		page.each do |place|
			extract_place_data(places, place) 
		end
		return places
	end

	protected
	def extract_place_data places, place_data
		place_data.chomp!
		new_place = Hash.new

		name = place_data.scan(/(^[^,]+)/)[0]
		return if name == nil
		new_place[:name] = name[0].strip

		types = place_data.scan(/(?<=, )([\s\S]+)(?=Адрес:)/)[0]
		return if types == nil
		new_place[:types] = types[0].strip.downcase.split(', ')
		new_place[:types_ids] = []

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
	def parse data
		places = Array.new
		data.css('div.kb_text').each do |bar_data|
			extract_place_data(places, bar_data)
		end
		return places
	end

	protected
	def extract_place_data places, place_data 
		new_place = Hash.new
		new_place[:name] = place_data.css('a').text

		blocks = place_data.css('p')
		size = blocks.size
		return if blocks == nil 

		types_id = 0
		address_id = 1
		phones_id = size - 1

		new_place[:types] = (types_id >= size) ? [] : blocks[types_id].text.downcase.strip.split(', ')
		new_place[:types_ids] = []

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

class Storage
	def initialize 
		begin
			@db = Mysql.init
			@db.options(Mysql::SET_CHARSET_NAME, 'utf8')
			@db.real_connect('localhost', DB_USER, DB_PASSWORD, DB_NAME)
		rescue Mysql::Error => e
			puts e.message
			puts e.backtrace
			self.shutdown
		end
	end

	def get_info sites
		sites.each do |site|
			parser = PageParser.new(@db, site)
			parser.proceed
		end
	end

	def update_geolocations
		uri = "http://maps.googleapis.com/maps/api/geocode/json?sensor=false&region=RU&address=%s"

		addresses = @db.query 'SELECT cafe_id, street, building FROM addresses'

		addresses.each_hash do |address|
			cafe_id = address['cafe_id']
			street = address['street'].force_encoding("utf-8")
			building = address['building'].force_encoding("utf-8")

			rest_query = URI::escape(uri % "Chelyabinsk,#{street},#{building}")

			begin
				geodata = open(rest_query).read
			rescue OpenURI::HTTPError => e
				puts e.message
				puts e.backtrace
				next
			end

			json = JSON.parse geodata

			next if json['status'] != 'OK'
			coords = json['results'][0]['geometry']['viewport']['northeast']

			longitude = coords['lng']
			latitude = coords['lat']

			@db.query "UPDATE addresses SET longitude = #{longitude}, latitude = #{latitude} WHERE cafe_id = #{cafe_id} AND street = #{street.inspect} AND building = #{building.inspect}"
		end
	end

	def generate_prices
		prices = String.new
		@db.query('SELECT id FROM cafes WHERE avg_price IS NULL').each_hash do |row|
			cafe_id = row['id']
			prices << ',' unless prices.empty?
			prices << '(' << cafe_id << ',' << ([*1..5].sample * 100).to_s << ')'
		end
		@db.query 'INSERT INTO cafes(id, avg_price) VALUES %s ON DUPLICATE KEY UPDATE avg_price = VALUES(avg_price)' % [prices] unless prices.empty?
	end

	def shutdown
		@db.close if @db	
	end
end

begin
	sites = [
		{:uri => 'http://chel.gobars.ru/bars/page_%i.html', :num => 6, :parser => GobarsParser},
		{:uri => 'http://www.resto74.ru/items/%i', :num => 33, :parser => Resto74Parser},
	]

	storage = Storage.new
	storage.get_info sites

	storage.generate_prices
	storage.update_geolocations

	storage.shutdown
end