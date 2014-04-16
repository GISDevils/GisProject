DROP DATABASE IF EXISTS `gis`;
CREATE DATABASE `gis`;

USE 'mysql';
GRANT ALL PRIVILEGES ON gis.* TO 'gis_user'@'localhost' IDENTIFIED BY 'qwerty'

WITH GRANT OPTION;
FLUSH PRIVILEGES;

USE gis;

CREATE TABLE cafes (
	id INT(10) PRIMARY KEY AUTO_INCREMENT,
	name VARCHAR(50) NOT NULL,
	phones VARCHAR(30),
	avg_price SMALLINT DEFAULT NULL,

	UNIQUE (name)
);

CREATE TABLE addresses (
	id INT(10) PRIMARY KEY AUTO_INCREMENT,
	cafe_id INT(10) NOT NULL,
	street VARCHAR(50) NOT NULL,
	building SMALLINT NOT NULL,
	latitude DECIMAL(18, 16) DEFAULT NULL,
	longitude DECIMAL(18, 16) DEFAULT NULL,

	UNIQUE(cafe_id, street, building),

	FOREIGN KEY (cafe_id) REFERENCES cafes(id)
);

CREATE TABLE cuisine_types (
	id SMALLINT PRIMARY KEY AUTO_INCREMENT,
	name VARCHAR(40) NOT NULL,

	UNIQUE(name)
);
INSERT INTO cuisine_types VALUES 
		(1, "австрийская"),
		(2, "авторская"),
		(3, "азербайджанская"),
		(4, "азиатская"),
		(5, "американская"),
		(6, "английская"),
		(7, "армянская"),
		(8, "восточная"),
		(9, "вьетнамская"),
		(10, "греческая"),
		(11, "грузинская"),
		(12, "домашняя"),
		(13, "европейская"),
		(14, "индийская"),
		(15, "индонезийская"),
		(16, "интернациональная"),
		(17, "итальянская"),
		(18, "кавказская"),
		(19, "китайская"),
		(20, "корейская"),
		(21, "малазийская"),
		(22, "мексиканская"),
		(23, "монгольская"),
		(24, "мясная"),
		(25, "немецкая"),
		(26, "непальская"),
		(27, "паназиатская"),
		(28, "пацанская"),
		(29, "персидская"),
		(30, "русская"),
		(31, "сербская"),
		(32, "советская"),
		(33, "средиземноморская"),
		(34, "тайская"),
		(35, "татарская"),
		(36, "турецкая"),
		(37, "узбекская"),
		(38, "уйгурская"),
		(39, "украинская"),
		(40, "французская"),
		(41, "чешская"),
		(42, "японская");

CREATE TABLE cafe_types (
	id SMALLINT PRIMARY KEY AUTO_INCREMENT,
	name VARCHAR(20) NOT NULL,

	UNIQUE(name)
);

INSERT INTO cafe_types (name) VALUES 
		("ресторан"),		# 1
		("кафе"),			# 2
		("бар"),			# 3
		("суши"),			# 4
		("пиццерия"),		# 5
		("караоке"),		# 6
		("доставка"),		# 7
		("паб"),			# 8
		("кофейня"),		# 9
		("банкетный зал"), 	# 10
		("ночной клуб"),	# 11
		("бильярд"),		# 12
		("развлекательный комплекс"), # 13
		("пироги"),			# 14
		("кондитерская"),	# 15
		("боулинг");		# 16

CREATE TABLE cuisines (
	cafe_id INT(10) NOT NULL,
	cuisine_id SMALLINT NOT NULL,

	UNIQUE(cafe_id, cuisine_id),

	FOREIGN KEY (cafe_id) REFERENCES cafes(id),
	FOREIGN KEY (cuisine_id) REFERENCES cuisine_types(id)
);

CREATE TABLE types (
	id INT(10) PRIMARY KEY AUTO_INCREMENT,
	cafe_id INT(10) NOT NULL,
	type_id SMALLINT NOT NULL,

	UNIQUE(cafe_id, type_id),

	FOREIGN KEY (cafe_id) REFERENCES cafes(id),
	FOREIGN KEY (type_id) REFERENCES cafe_types(id)
);