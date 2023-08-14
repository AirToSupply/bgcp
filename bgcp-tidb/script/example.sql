CREATE DATABASE pingcap;

USE pingcap;

CREATE TABLE `tab_tidb` (
`id` int(11) NOT NULL AUTO_INCREMENT,
`name` varchar(20) NOT NULL DEFAULT '',
`age` int(11) NOT NULL DEFAULT 0,
`version` varchar(20) NOT NULL DEFAULT '',
PRIMARY KEY (`id`),
KEY `idx_age` (`age`));

INSERT INTO `tab_tidb` values (1,'TiDB',5,'TiDB-v5.0.0');

SELECT * FROM tab_tidb;

DROP DATABASE pingcap;
