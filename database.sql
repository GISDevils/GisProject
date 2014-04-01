CREATE DATABASE gis;

CREATE TABLE cafes (
	id INT(10) PRIMARY KEY AUTO INCREMENT,
	name VARCHAR(50) NOT NULL,
	phones VARCHAR(30),
	min_price SMALLINT DEFAULT NULL,

	UNIQUE (name)
);

CREATE TABLE addresses (
	cafe_id INT(10) NOT NULL,
	address VARCHAR(50) NOT NULL,

	UNIQUE(cafe_id, address),

	FOREIGN KEY (cafe_id) REFERENCES cafes(id)
);

CREATE TABLE cuisine_types (
	id SMALLINT PRIMARY KEY AUTO INCREMENT,
	name VARCHAR(40) NOT NULL,

	UNIQUE(name)
);

CREATE TABLE cafe_types (
	id SMALLINT PRIMARY KEY AUTO INCREMENT,
	name VARCHAR(20) NOT NULL,

	UNIQUE(name)
);

CREATE TABLE cuisines (
	cafe_id INT(10) NOT NULL,
	cuisine_id SMALLINT NOT NULL,

	UNIQUE(cafe_id, cuisine_id),

	FOREIGN KEY (cafe_id) REFERENCES cafes(id),
	FOREIGN KEY (cuisine_id) REFERENCES cuisine_types(id)
);

CREATE TABLE types (
	cafe_id INT(10) NOT NULL,
	type_id SMALLINT NOT NULL,

	UNIQUE(cafe_id, type_id),

	FOREIGN KEY (cafe_id) REFERENCES cafes(id),
	FOREIGN KEY (type_id) REFERENCES cafe_types(id)
);