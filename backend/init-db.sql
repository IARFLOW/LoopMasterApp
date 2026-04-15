CREATE DATABASE IF NOT EXISTS loopmaster
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS 'loopmaster'@'localhost' IDENTIFIED BY 'loopmaster';

GRANT ALL PRIVILEGES ON loopmaster.* TO 'loopmaster'@'localhost';

FLUSH PRIVILEGES;
