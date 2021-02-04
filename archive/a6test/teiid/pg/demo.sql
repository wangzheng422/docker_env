create database test;

\connect "test";

DROP TABLE IF EXISTS "t1";
CREATE TABLE "public"."t1" (
    "id" character varying(500) NOT NULL,
    "name" character varying(500) NOT NULL
) WITH (oids = false);

TRUNCATE "t1";
INSERT INTO "t1" ("id", "name") VALUES
('1',	'1');