#!/usr/bin/ruby
# encoding: UTF-8

require 'mysql'
require 'rubygems'
require 'nokogiri'
require 'open-uri'

require_relative 'secrets'

def extract_unique_values(hash_array, key)
	values = Array.new
	hash_array.map do |hash|
		values << (Array.new << hash[key])
	end

	result = values.flatten.uniq
	return values.flatten.uniq
end
 
def surround_values(values)
	surrounded_values = String.new
	values.each do |value|
		surrounded_values << "," unless surrounded_values.empty?
		surrounded_values << '("' << value << '")'
	end

	return surrounded_values
end
 
def quote_values(values)
	quoted_values = String.new
	values.each do |value|
		quoted_values << "," unless quoted_values.empty?
		quoted_values << '"' << value << '"'
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
			@places = @site[:parser].parse(page)

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
		@db.query "INSERT IGNORE INTO #{table_name}(name) VALUES %s" % surround_values(values)
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
	def insert_addresses()
		addresses = String.new
		@places.each do |place|
			addresses << "," unless addresses.empty?
			addresses << '(' << place[:id].to_s << ',"' << place[:address] << '")' unless place[:id] == nil or place[:address] == nil
		end
		puts addresses
		@db.query "INSERT IGNORE INTO addresses VALUES %s" % addresses unless addresses.empty?
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

class GobarsParser
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
		return if name_arr == nil
		name = name_arr[0]

		types = place_data.scan(/(?<=, )([\s\S]+)(?=Адрес:)/)[0]
		return if types == nil
		types = types[0].split(', ')

		address = place_data.scan(/(?<=Адрес: )([\s\S]+)(?=Телефон:)/)[0]
		return if address == nil
		address = address[0]

		phones_list = place_data.scan(/(?<=Телефон: )([\s\S]+)(?=Кухня:)/)[0]
		return if phones_list == nil
		phones = phones_list[0].gsub(':w', '').split(', ')

		cuisins_list = place_data.scan(/(?<=Кухня: )([A-Zа-я\,\s]*)/)[0]
		return if cuisins_list == nil
		cuisins = cuisins_list[0].strip.split(', ')

		places << {:name => name, :types => types, :phones => phones, :cuisins => cuisins, :address => address, :min_price => "0"}
	end
end

begin
	sites = [
		{:uri => 'http://chel.gobars.ru/bars/page_%i.html', :num => 6},
		#{:uri => 'http://www.resto74.ru/items/%i', :num => 33, :parser => GobarsParser.new}
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