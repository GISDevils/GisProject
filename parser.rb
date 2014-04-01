#!/usr/bin/ruby
# encoding: UTF-8

require 'mysql'
require 'rubygems'
require 'nokogiri'
require 'open-uri'

require_relative 'secrets'

class PageParser
	def initialize(db, site)
		@db = db
		@site = site
	end

	def proceed()
		@site[:num].times do |i|
			page = Nokogiri::HTML(open(@site[:uri] % i))
			@places = @site[:parser].parse(page)

			self.insert_cuisines
			self.insert_types
			self.insert_cafes
		
			self.associate_cafes
		end
	end

	protected
	def insert_cafes()
		places_names = String.new
		@places.each do |place|
			places_names << ',' unless places_names.empty?
			places_names << '("' << place[:name] << '","' << place[:phones].join(',') << '","' << place[:min_price] << '")'
		end

		@db.query ('INSERT IGNORE INTO cafes(name, phones, min_price) VALUES %s' % [places_names])

		ids = @db.query 'SELECT id, name FROM cafes WHERE (name, phones, min_price) IN (%s)' % [places_names]
		ids.each_hash do |id|
			@places.select {|place| place[:name] == id['name']}.each do |place|
				place[:id] = id['id']
			end
		end
	end

	protected 
	def insert_cuisines()
		cuisins = extract_unique_values(@places, :cuisins)
		insert_values(cuisins, ["name"], 'cuisine_types') unless cuisins == nil
	end

	protected 
	def insert_types()
		types = extract_unique_values(@places, :types)
		insert_values(types, ["name"], 'cafe_types') unless types == nil
	end

	protected
	def associate_cafes
		@places.each do |place|
			#TODO
			types = String.new
			place[types]
			cuisines = String.new


			@db.query "INSERT IGNORE INTO types SELECT %i, id FROM cafe_types WHERE name IN (%s)" % [place[:id], place[:cuisins].join(',')]
			@db.query "INSERT IGNORE INTO cuisines SELECT %i, id FROM cuisine_types WHERE name IN (%s)" % [place[:id], place[:types].join(',')]
		end
	end

	protected
	def extract_unique_values(hash_array, key)
		values = Array.new
		hash_array.map do |hash|
			values << (Array.new << hash[key])
		end

		result = values.flatten.uniq
		return values.flatten.uniq
	end

	protected
	def insert_values(values, fields, table_name)
		query = "INSERT IGNORE INTO #{table_name}(%s) VALUES %s" % [fields.join(','), self.get_quoted_values(values)]
		@db.query query
	end

	protected 
	def get_quoted_values(values)
		quoted_values = String.new
		values.each do |value|
			quoted_values << "," unless quoted_values.empty?
			quoted_values << '("' << value << '")' unless value == nil
		end
	end
end

class ParserGobars
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

		name_arr = place_data.scan(/(^[^,]+)/)[0]
		return if name_arr.class == nil.class
		name = name_arr[0]

		types = place_data.scan(/(?<=, )([\s\S]+)(?=Адрес:)/)[0]
		return if types.class == nil.class
		types = types[0].split(', ')

		phones_list = place_data.scan(/(?<=Телефон: )([\s\S]+)(?=Кухня:)/)[0]
		return if phones_list.class == nil.class
		phones = phones_list[0].split(', ')

		cuisins_list = place_data.scan(/(?<=Кухня: )([A-Zа-я\,\s]*)/)[0]
		return if cuisins_list.class == nil.class
		cuisins = cuisins_list[0].strip.split(', ')

		places << {:name => name, :types => types, :phones => phones, :cuisins => cuisins, :min_price => "0"}
	end
end

begin
	sites = [
		#{:uri => 'http://chel.gobars.ru/bars/page_%i.html', :num => 6},
		{:uri => 'http://www.resto74.ru/items/%i', :num => 33, :parser => ParserGobars.new}
	]

	db = Mysql.init
	db.options(Mysql::SET_CHARSET_NAME, 'utf8')
	db.real_connect('localhost', DB_USER, DB_PASSWORD, DB_NAME)

	sites.each do |site|
		parser = PageParser.new(db, site)
		parser.proceed
	end

	db.close if db
end