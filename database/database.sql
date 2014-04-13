DROP DATABASE IF EXISTS `gis`;
CREATE DATABASE `gis`;

USE 'mysql';
GRANT ALL PRIVILEGES ON gis.* TO 'gis_user'@'localhost' IDENTIFIED BY 'qwerty'

WITH GRANT OPTION;
FLUSH PRIVILEGES;

CREATE TABLE gis.cafes (
	id INT(10) PRIMARY KEY AUTO_INCREMENT,
	name VARCHAR(50) NOT NULL,
	phones VARCHAR(30),
	min_price SMALLINT DEFAULT NULL,

	UNIQUE (name)
);

CREATE TABLE gis.addresses (
	cafe_id INT(10) NOT NULL,
	street VARCHAR(50) NOT NULL,
	building SMALLINT NOT NULL,
	latitude DECIMAL(18, 16) DEFAULT NULL,
	longitude DECIMAL(18, 16) DEFAULT NULL,

	UNIQUE(cafe_id, street, building),

	FOREIGN KEY (cafe_id) REFERENCES cafes(id)
);

CREATE TABLE gis.cuisine_types (
	id INT(10) PRIMARY KEY AUTO_INCREMENT,
	name VARCHAR(40) NOT NULL,

	UNIQUE(name)
);

CREATE TABLE gis.cafe_types (
	id INT(10) PRIMARY KEY AUTO_INCREMENT,
	name VARCHAR(20) NOT NULL,

	UNIQUE(name)
);

CREATE TABLE gis.cuisines (
	cafe_id INT(10) NOT NULL,
	cuisine_id INT(10) NOT NULL,

	UNIQUE(cafe_id, cuisine_id),

	FOREIGN KEY (cafe_id) REFERENCES cafes(id),
	FOREIGN KEY (cuisine_id) REFERENCES cuisine_types(id)
);

CREATE TABLE gis.types (
	cafe_id INT(10) NOT NULL,
	type_id INT(10) NOT NULL,

	UNIQUE(cafe_id, type_id),

	FOREIGN KEY (cafe_id) REFERENCES cafes(id),
	FOREIGN KEY (type_id) REFERENCES cafe_types(id)
);