-- Progettazione Web 
DROP DATABASE if exists ms_db; 
CREATE DATABASE ms_db; 
USE ms_db; 
-- MySQL dump 10.13  Distrib 5.7.28, for Win64 (x86_64)
--
-- Host: localhost    Database: ms_db
-- ------------------------------------------------------
-- Server version	5.7.28

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `account`
--

DROP TABLE IF EXISTS `account`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `account` (
  `username` varchar(255) NOT NULL,
  `mail` varchar(255) NOT NULL,
  `passwordHash` varchar(255) NOT NULL,
  `tspPrimoAccesso` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`username`),
  UNIQUE KEY `mail` (`mail`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `account`
--

LOCK TABLES `account` WRITE;
/*!40000 ALTER TABLE `account` DISABLE KEYS */;
INSERT INTO `account` VALUES ('davide.bianchi0','davide.bianchi@example.com','$2y$10$xJRsxAwyYL67eDshjQevOOS36OlNrxvSKfOVeHkdFjXpL3/Zy4KcS','2025-01-27 09:43:48'),('mario.verdi0','mario.verdi@example.com','$2y$10$ZwB3jEDoblFHnZd2JiUtMe1sIYwjHmQMl8B6fXl2i9jEPXeFVp/u.','2025-01-27 09:44:53'),('michele.S0','michele.S@example.com','$2y$10$zNFSdoeVy.BEFkpBmXS6PuMoGV8237vda3W2YomZZea5qapG4/wRq','2025-01-27 10:21:33');
/*!40000 ALTER TABLE `account` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `artista`
--

DROP TABLE IF EXISTS `artista`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `artista` (
  `username` varchar(255) NOT NULL,
  `nome` varchar(255) NOT NULL,
  `cognome` varchar(255) NOT NULL,
  `nomeArtistico` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`username`),
  UNIQUE KEY `nomeArtistico` (`nomeArtistico`),
  CONSTRAINT `artista_ibfk_1` FOREIGN KEY (`username`) REFERENCES `account` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `artista`
--

LOCK TABLES `artista` WRITE;
/*!40000 ALTER TABLE `artista` DISABLE KEYS */;
INSERT INTO `artista` VALUES ('davide.bianchi0','Davide','Bianchi','Whiiten'),('mario.verdi0','Mario','Verdi','Griin'),('michele.S0','Michele','S','Mihel Noir');
/*!40000 ALTER TABLE `artista` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `genere`
--

DROP TABLE IF EXISTS `genere`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `genere` (
  `id` int(4) NOT NULL AUTO_INCREMENT,
  `nome` varchar(255) NOT NULL,
  `descrizione` text,
  PRIMARY KEY (`id`),
  UNIQUE KEY `nome` (`nome`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `genere`
--

LOCK TABLES `genere` WRITE;
/*!40000 ALTER TABLE `genere` DISABLE KEYS */;
INSERT INTO `genere` VALUES (1,'',NULL),(2,'Generative','Delve into the enchanting realm of generative art, where the fusion of algorithms and human ingenuity births astonishing masterpieces that constantly evolve. Witness a seamless blend of art and technology, creating an ever-changing landscape of visual wonders.'),(3,'Glitch','Revel in the unconventional allure of glitch art, a celebration of digital irregularities and serendipitous outcomes that defy traditional aesthetic norms. Experience the beauty of chaos, as artists harness the power of digital errors to craft visually arresting pieces.'),(4,'Illustration','Immerse yourself in abstract illustration\'s captivating realm, where vibrant colors, intricate patterns, and innovative forms intertwine. Boundaries vanish as imagination soars, inviting interpretation. Explore the vivid tapestry, where simplicity meets complexity, igniting creative journeys. Step into the world of abstract art and unleash your imagination.'),(5,'Animation','Explore the captivating realm of animation, where imagination thrives. With the fusion of art and technology, characters and landscapes spring to life, enchanting audiences of all ages. Experience the magic of animated wonders and let your imagination soar to new heights.'),(6,'Photography','Uncover the boundless potential of digital photography, as artists push the envelope of the medium, transforming our perception and interpretation of the world around us. Experience a vivid tapestry of visual stories, where technology meets artistic vision.'),(7,'Motion','Engage your senses in the exhilarating domain of motion art, where fluid movement and metamorphosis take center stage, sculpting immersive visual experiences that captivate the mind and ignite the imaginatio'),(8,'Immersive','Explore what the virtual reality has to offer'),(9,'AI','Embark on a journey into the mesmerizing realm of AI art, transcending traditional conventions and exploring new frontiers of creativity.'),(10,'Abstract','Discover digital abstract art, the captivating fusion of technology and creativity that transcends traditional artistry. Born from pioneers like Harold Cohen in 1968, this art form has evolved into a mesmerizing blend of vibrant colors, striking patterns, and cutting-edge forms. Immerse yourself in the future of abstract art today.');
/*!40000 ALTER TABLE `genere` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `opera`
--

DROP TABLE IF EXISTS `opera`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `opera` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `serie` int(4) NOT NULL,
  `titolo` varchar(255) NOT NULL,
  `artista` varchar(255) NOT NULL,
  `prezzo` float DEFAULT NULL,
  `genere` int(4) NOT NULL,
  `path` varchar(255) DEFAULT NULL,
  `dataPubblicazione` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `serie` (`serie`),
  KEY `artista` (`artista`),
  KEY `genere` (`genere`),
  CONSTRAINT `opera_ibfk_1` FOREIGN KEY (`serie`) REFERENCES `serie` (`id`),
  CONSTRAINT `opera_ibfk_2` FOREIGN KEY (`artista`) REFERENCES `artista` (`username`),
  CONSTRAINT `opera_ibfk_3` FOREIGN KEY (`genere`) REFERENCES `genere` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `opera`
--

LOCK TABLES `opera` WRITE;
/*!40000 ALTER TABLE `opera` DISABLE KEYS */;
INSERT INTO `opera` VALUES (1,2,'0002.jpg','davide.bianchi0',NULL,2,'C:\\pweb\\tools\\XAMPP\\htdocs\\progetto\\ms_db\\assets\\images\\davide.bianchi0\\2\\0002.jpg','2023-10-20 19:14:04'),(2,2,'0003.jpg','davide.bianchi0',NULL,2,'C:\\pweb\\tools\\XAMPP\\htdocs\\progetto\\ms_db\\assets\\images\\davide.bianchi0\\2\\0003.jpg','2023-10-20 19:14:04'),(3,3,'0445.jpg','mario.verdi0',NULL,2,'C:\\pweb\\tools\\XAMPP\\htdocs\\progetto\\ms_db\\assets\\images\\mario.verdi0\\3\\0445.jpg','2024-07-17 09:17:12'),(4,3,'0497.jpg','mario.verdi0',NULL,2,'C:\\pweb\\tools\\XAMPP\\htdocs\\progetto\\ms_db\\assets\\images\\mario.verdi0\\3\\0497.jpg','2024-07-17 09:17:12'),(5,3,'0513.jpg','mario.verdi0',NULL,2,'C:\\pweb\\tools\\XAMPP\\htdocs\\progetto\\ms_db\\assets\\images\\mario.verdi0\\3\\0513.jpg','2024-07-17 09:17:12'),(6,3,'0612.jpg','mario.verdi0',NULL,2,'C:\\pweb\\tools\\XAMPP\\htdocs\\progetto\\ms_db\\assets\\images\\mario.verdi0\\3\\0612.jpg','2024-07-17 09:17:12'),(7,3,'0082.jpg','mario.verdi0',NULL,2,'C:\\pweb\\tools\\XAMPP\\htdocs\\progetto\\ms_db\\assets\\images\\mario.verdi0\\3\\0082.jpg','2024-07-17 09:17:12'),(8,3,'0334.jpg','mario.verdi0',NULL,2,'C:\\pweb\\tools\\XAMPP\\htdocs\\progetto\\ms_db\\assets\\images\\mario.verdi0\\3\\0334.jpg','2024-07-17 09:17:12'),(9,1,'Sputnik.png','michele.S0',NULL,2,'C:\\pweb\\tools\\XAMPP\\htdocs\\progetto\\ms_db\\assets\\images\\michele.S0\\1\\Sputnik.png','2025-01-27 10:32:02'),(10,1,'Selva.png','michele.S0',NULL,9,'C:\\pweb\\tools\\XAMPP\\htdocs\\ms_db\\assets\\images\\michele.S0\\1\\Selva.png','2025-01-27 17:50:30');
/*!40000 ALTER TABLE `opera` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `serie`
--

DROP TABLE IF EXISTS `serie`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `serie` (
  `id` int(4) NOT NULL AUTO_INCREMENT,
  `titolo` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `titolo` (`titolo`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `serie`
--

LOCK TABLES `serie` WRITE;
/*!40000 ALTER TABLE `serie` DISABLE KEYS */;
INSERT INTO `serie` VALUES (2,'Particle Trails'),(1,'Singoli'),(3,'Typograph');
/*!40000 ALTER TABLE `serie` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2025-02-03 16:16:42
