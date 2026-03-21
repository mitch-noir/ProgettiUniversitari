DROP DATABASE IF EXISTS ms_db;
CREATE DATABASE ms_db;
USE ms_db;

DROP TABLE IF EXISTS `account`;
CREATE TABLE `account` (
    `username`      VARCHAR(255) NOT NULL, 
    `mail`          VARCHAR(255) NOT NULL UNIQUE, 
    `passwordHash`  VARCHAR(255) NOT NULL, 
    `tspPrimoAccesso`   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY(`username`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1; 

DROP TABLE IF EXISTS `genere`;
CREATE TABLE `genere` (
    `id`            INT(4) NOT NULL AUTO_INCREMENT, 
    `nome`          VARCHAR(255) NOT NULL UNIQUE,     
    `descrizione`   TEXT DEFAULT NULL, 
    PRIMARY KEY(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1; 

DROP TABLE IF EXISTS `artista`;
CREATE TABLE `artista` (
    `username`      VARCHAR(255) NOT NULL, 
    `nome`          VARCHAR(255) NOT NULL, 
    `cognome`       VARCHAR(255) NOT NULL, 
    `nomeArtistico` VARCHAR(255) DEFAULT NULL UNIQUE,     
    PRIMARY KEY(`username`), 
    FOREIGN KEY(`username`) REFERENCES `account`(`username`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1; 



DROP TABLE IF EXISTS `serie`;
CREATE TABLE `serie` (
    `id`            INT(4) NOT NULL AUTO_INCREMENT, 
    `titolo`        VARCHAR(255) NOT NULL UNIQUE,     
    PRIMARY KEY(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1; 

DROP TABLE IF EXISTS `opera`;
CREATE TABLE `opera` (
    `id`            INT(10) NOT NULL AUTO_INCREMENT, 
    `serie`         INT(4) NOT NULL, 
    `titolo`        VARCHAR(255) NOT NULL,     
    `artista`       VARCHAR(255) NOT NULL, 
    `prezzo`        FLOAT(20) DEFAULT NULL, 
    `genere`        INT(4) NOT NULL,
    `path`          VARCHAR(255) DEFAULT NULL, -- NULL o no?
    `dataPubblicazione` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY(`id`), 
    FOREIGN KEY(`serie`) REFERENCES `serie`(`id`),
    FOREIGN KEY(`artista`) REFERENCES `artista`(`username`),
    FOREIGN KEY(`genere`) REFERENCES `genere`(`id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1; 

INSERT INTO `genere` (`nome`, `descrizione`) VALUES
("", NULL), 
("Generative", "Delve into the enchanting realm of generative art, where the fusion of algorithms and human ingenuity births astonishing masterpieces that constantly evolve. Witness a seamless blend of art and technology, creating an ever-changing landscape of visual wonders."),
("Glitch", "Revel in the unconventional allure of glitch art, a celebration of digital irregularities and serendipitous outcomes that defy traditional aesthetic norms. Experience the beauty of chaos, as artists harness the power of digital errors to craft visually arresting pieces."),
("Illustration", "Immerse yourself in abstract illustration's captivating realm, where vibrant colors, intricate patterns, and innovative forms intertwine. Boundaries vanish as imagination soars, inviting interpretation. Explore the vivid tapestry, where simplicity meets complexity, igniting creative journeys. Step into the world of abstract art and unleash your imagination."),
("Animation", "Explore the captivating realm of animation, where imagination thrives. With the fusion of art and technology, characters and landscapes spring to life, enchanting audiences of all ages. Experience the magic of animated wonders and let your imagination soar to new heights."),
("Photography", "Uncover the boundless potential of digital photography, as artists push the envelope of the medium, transforming our perception and interpretation of the world around us. Experience a vivid tapestry of visual stories, where technology meets artistic vision."),
("Motion", "Engage your senses in the exhilarating domain of motion art, where fluid movement and metamorphosis take center stage, sculpting immersive visual experiences that captivate the mind and ignite the imaginatio"),
("Immersive", "Explore what the virtual reality has to offer"),
("AI", "Embark on a journey into the mesmerizing realm of AI art, transcending traditional conventions and exploring new frontiers of creativity."),
("Abstract", "Discover digital abstract art, the captivating fusion of technology and creativity that transcends traditional artistry. Born from pioneers like Harold Cohen in 1968, this art form has evolved into a mesmerizing blend of vibrant colors, striking patterns, and cutting-edge forms. Immerse yourself in the future of abstract art today.");

INSERT INTO `serie` (`id`, `titolo`) VALUES
(1, "Singoli"),
(2, "Particle Trails"),
(3, "Typograph");

INSERT INTO `account` (`username`, `mail`, `passwordHash`, `tspPrimoAccesso`) VALUES
("davide.bianchi0", "davide.bianchi@example.com", "$2y$10$xJRsxAwyYL67eDshjQevOOS36OlNrxvSKfOVeHkdFjXpL3/Zy4KcS", "2025-01-27 10:43:48"),
("mario.verdi0", "mario.verdi@example.com", "$2y$10$ZwB3jEDoblFHnZd2JiUtMe1sIYwjHmQMl8B6fXl2i9jEPXeFVp/u.", "2025-01-27 10:44:53"),
("michele.S0",	"michele.S@example.com", "$2y$10$zNFSdoeVy.BEFkpBmXS6PuMoGV8237vda3W2YomZZea5qapG4/wRq", "2025-01-27 11:21:33");


INSERT INTO `artista` (`username`, `nome`, `cognome`, `nomeArtistico`) VALUES
("davide.bianchi0", "Davide", "Bianchi", "Whiiten"),
("mario.verdi0", "Mario", "Verdi", "Griin"),
("michele.S0", "Michele", "S", "Mihel Noir");


INSERT INTO `opera` (`id`, `serie`, `titolo`, `artista`, `prezzo`, `genere`, `path`, `dataPubblicazione`) VALUES
(1, 2,	"0002.jpg",	"davide.bianchi0",  NULL,   2,	"C:\\pweb\\tools\\XAMPP\\htdocs\\progetto\\ms_db\\assets\\images\\davide.bianchi0\\2\\0002.jpg",	"2023-10-20 21:14:04"),
(2, 2,	"0003.jpg",	"davide.bianchi0",  NULL,   2,	"C:\\pweb\\tools\\XAMPP\\htdocs\\progetto\\ms_db\\assets\\images\\davide.bianchi0\\2\\0003.jpg",	"2023-10-20 21:14:04"),
(3, 3,	"0445.jpg",	"mario.verdi0", NULL,   2,	"C:\\pweb\\tools\\XAMPP\\htdocs\\progetto\\ms_db\\assets\\images\\mario.verdi0\\3\\0445.jpg",	"2024-07-17 11:17:12"),
(4, 3,	"0497.jpg",	"mario.verdi0", NULL,   2,	"C:\\pweb\\tools\\XAMPP\\htdocs\\progetto\\ms_db\\assets\\images\\mario.verdi0\\3\\0497.jpg",	"2024-07-17 11:17:12"),
(5, 3,	"0513.jpg",	"mario.verdi0", NULL,   2,	"C:\\pweb\\tools\\XAMPP\\htdocs\\progetto\\ms_db\\assets\\images\\mario.verdi0\\3\\0513.jpg",	"2024-07-17 11:17:12"),
(6, 3,	"0612.jpg",	"mario.verdi0", NULL,   2,	"C:\\pweb\\tools\\XAMPP\\htdocs\\progetto\\ms_db\\assets\\images\\mario.verdi0\\3\\0612.jpg",	"2024-07-17 11:17:12"),
(7, 3,	"0082.jpg",	"mario.verdi0", NULL,   2,	"C:\\pweb\\tools\\XAMPP\\htdocs\\progetto\\ms_db\\assets\\images\\mario.verdi0\\3\\0082.jpg",	"2024-07-17 11:17:12"),
(8, 3,	"0334.jpg",	"mario.verdi0", NULL,   2,	"C:\\pweb\\tools\\XAMPP\\htdocs\\progetto\\ms_db\\assets\\images\\mario.verdi0\\3\\0334.jpg",	"2024-07-17 11:17:12"),
(9, 1,	"Sputnik.png",	"michele.S0",  NULL,   2,	"C:\\pweb\\tools\\XAMPP\\htdocs\\progetto\\ms_db\\assets\\images\\michele.S0\\1\\Sputnik.png",    "2025-01-27 11:32:02"),
(10, 1,	"Selva.png",    "michele.S0",  NULL,  9, "C:\\pweb\\tools\\XAMPP\\htdocs\\ms_db\\assets\\images\\michele.S0\\1\\Selva.png", 	"2025-01-27 18:50:30");
