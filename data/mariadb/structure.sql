-- Adminer 4.7.8 MySQL dump
SET NAMES utf8;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;
SET sql_mode = 'NO_AUTO_VALUE_ON_ZERO';
SET NAMES utf8mb4;

DROP TABLE IF EXISTS `appointments`;
CREATE TABLE `appointments` (
    `uuid` varchar(36) COLLATE utf8mb4_german2_ci NOT NULL,
    `datetime` datetime NOT NULL,
    `street_id` int(10) unsigned NOT NULL,
    `collection_id` tinyint(3) unsigned NOT NULL,
    PRIMARY KEY (`datetime`,`street_id`,`collection_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_german2_ci;

DROP TABLE IF EXISTS `cities`;
CREATE TABLE `cities` (
    `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
    `city` varchar(255) COLLATE utf8mb4_german2_ci NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_german2_ci;

DROP TABLE IF EXISTS `collections`;
CREATE TABLE `collections` (
    `id` tinyint(3) unsigned NOT NULL AUTO_INCREMENT,
    `name` varchar(255) COLLATE utf8mb4_german2_ci NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_german2_ci;

INSERT INTO `collections` (`id`, `name`) VALUES
(1,	'Restmüll 14-tgl.'),
(2,	'Restmüll 4-wö.'),
(3,	'Kompost'),
(4,	'Altpapier'),
(5,	'Gelber Sack'),
(6,	'Saisonkompost');

DROP TABLE IF EXISTS `streets`;
CREATE TABLE `streets` (
    `id` int(10) unsigned NOT NULL,
    `name` varchar(255) COLLATE utf8mb4_german2_ci NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_german2_ci;


-- 2020-12-14 12:49:59
