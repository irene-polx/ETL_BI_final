CREATE SCHEMA DWH_FLIGHTS;

-------------------Dim_Calendar------------------------------------
DROP TABLE  DWH_FLIGHTS.Dim_Calendar ;

CREATE TABLE DWH_FLIGHTS.Dim_Calendar 
AS
WITH dates AS (
    SELECT dd::date AS dt
    FROM generate_series
            ('2010-01-01'::timestamp
            , '2030-01-01'::timestamp
            , '1 day'::interval) dd
)
SELECT
    to_char(dt, 'YYYYMMDD')::int AS id,
    dt AS date,
    to_char(dt, 'YYYY-MM-DD') AS ansi_date,
    date_part('isodow', dt)::int AS day,
    date_part('week', dt)::int AS week_number,
    date_part('month', dt)::int AS month,
    date_part('isoyear', dt)::int AS year,
    (date_part('isodow', dt)::smallint BETWEEN 1 AND 5)::int AS week_day,
    (to_char(dt, 'YYYYMMDD')::int IN (
        20130101, 20130102,  20130103,
        20130104, 20130105,  20130106,
        20130107, 20130108,  20130223,
        20130308, 20130310,  20130501,
        20130502, 20130503,  20130509,
        20130510, 20130612,  20131104,
        20140101, 20140102,  20140103,
        20140104, 20140105,  20140106,
        20140107, 20140108,  20140223,
        20140308, 20140310,  20140501,
        20140502, 20140509,  20140612,
        20140613, 20141103,  20141104,
        20150101, 20150102,  20150103,
        20150104, 20150105,  20150106,
        20150107, 20150108,  20150109,
        20150223, 20150308,  20150309,
        20150501, 20150504,  20150509,
        20150511, 20150612,  20151104,
        20160101, 20160102,  20160103,
        20160104, 20160105,  20160106,
        20160107, 20160108,  20160222,
        20160223, 20160307,  20160308,
        20160501, 20160502,  20160503,
        20160509, 20160612,  20160613,
        20161104, 20170101,  20170102,
        20170103, 20170104,  20170105,
        20170106, 20170107,  20170108,
        20170223, 20170224,        20170308,
        20170501,        20170508,        20170509,
        20170612,        20171104,        20171106,
        20180101,        20180102,        20180103,
        20180104,        20180105,        20180106,
        20180107,        20180108,        20180223,
        20180308,        20180309,        20180430,
        20180501,        20180502,        20180509,
        20180611,        20180612,        20181104,
        20181105,        20181231,        20190101,
        20190102,        20190103,        20190104,
        20190105,        20190106,        20190107,
        20190108,        20190223,        20190308,
        20190501,        20190502,        20190503,
        20190509,        20190510,        20190612,
        20191104,
        20200101, 20200102, 20200103, 20200106, 20200107, 20200108,
       20200224, 20200309, 20200501, 20200504, 20200505, 20200511,
       20200612, 20201104))::int AS holiday
FROM dates
ORDER BY dt;

ALTER TABLE DWH_FLIGHTS.Dim_Calendar  ADD PRIMARY KEY (id);
------------------------------------------------------
--------------------Dim_Passengers - справочник пассажиров-----------------
DROP TABLE DWH_FLIGHTS.Dim_Passenger ;

CREATE TABLE DWH_FLIGHTS.Dim_Passenger (
    id serial not null primary key,
    passenger_id varchar(20) NOT NULL, 
    passenger_name varchar(100) not null,
    phone varchar(100) null,
    email varchar(100) null
);

DROP TABLE DWH_FLIGHTS.Reject_Passenger ;

CREATE TABLE DWH_FLIGHTS.Reject_Passenger (
    passenger_id varchar(20), 
    passenger_name varchar(100),
    phone varchar(100),
    email varchar(100)
);
--bookings.tickets
-------------------Dim_Aircrafts - справочник самолетов--------------------
DROP TABLE  DWH_FLIGHTS.Dim_Aircraft ;

CREATE TABLE DWH_FLIGHTS.Dim_Aircraft (
    id serial not null primary key,
  	aircraft_code bpchar(3) NOT NULL,
	model_en varchar(100) NOT NULL,
	model_ru varchar(100) NOT NULL,
	"range" int4 NOT NULL
);
DROP TABLE DWH_FLIGHTS.Reject_Aircraft ;

CREATE TABLE DWH_FLIGHTS.Reject_Aircraft (
    aircraft_code varchar(100),
	model_en varchar(100) NOT NULL,
	model_ru varchar(100) NOT NULL,
	"range" varchar(100)
);

------------------Dim_Airports - справочник аэропортов---------------------
DROP TABLE   DWH_FLIGHTS.Dim_Airport ;

CREATE TABLE DWH_FLIGHTS.Dim_Airport (
    id serial not null primary key,
  	airport_code bpchar(3) NOT NULL,
	airport_name_en varchar(100) NOT NULL,
	airport_name_ru varchar(100) NOT NULL,
	city_en varchar(100) NOT NULL,
	city_ru varchar(100) NOT NULL,
	timezone text NOT NULL
);
DROP TABLE DWH_FLIGHTS.Reject_Airport ;

CREATE TABLE DWH_FLIGHTS.Reject_Airport (
	airport_code bpchar(3) NOT NULL,
	airport_name_en varchar(100) NOT NULL,
	airport_name_ru varchar(100) NOT NULL,
	city_en varchar(100) NOT NULL,
	city_ru varchar(100) NOT NULL,
	timezone text NOT NULL
);

----------------Dim_Tariff - справочник тарифов (Эконом/бизнес и тд)-------
DROP TABLE  DWH_FLIGHTS.Dim_Tarif ;

CREATE TABLE DWH_FLIGHTS.Dim_Tarif (
    id serial not null primary key,
	tarif_name_en varchar(100) NOT null,
	tarif_name_ru varchar(100) NOT NULL
);
DROP TABLE DWH_FLIGHTS.Reject_Tarif ;

CREATE TABLE DWH_FLIGHTS.Reject_Tarif (
    tarif_name_en varchar(100) null,
	tarif_name_ru varchar(100) NULL
);
--bookings.ticket_flights
--CHECK (fare_conditions IN ('Economy', 'Comfort', 'Business'))

--------------Fact_Flights - содержит совершенные перелеты.
-- Если в рамках билета был сложный маршрут с пересадками - каждый сегмент учитываем независимо

DROP TABLE  DWH_FLIGHTS.Fact_Flight;

CREATE TABLE DWH_FLIGHTS.Fact_Flight (
    passenger_key int not null references DWH_FLIGHTS.Dim_Passenger(id),--Пассажир
    aircraft_key int not null references DWH_FLIGHTS.Dim_Aircraft(id),---Самолет
    departure_airport_key int references DWH_FLIGHTS.Dim_Airport(id),--Аэропорт вылета
    arrival_airport_key int references DWH_FLIGHTS.Dim_Airport(id),--Аэропорт прилета
    tarif_key int not null references DWH_FLIGHTS.Dim_Tarif(id),--Класс обслуживания
    departure_date_key int not null references DWH_FLIGHTS.Dim_Calendar(id),--Дата вылета (фактическая)
    arrival_date_key int not null references DWH_FLIGHTS.Dim_Calendar(id),--Дата прилета (фактическая)
    flight_id int NOT NULL,
	flight_no bpchar(6) NOT NULL,
    departure_dt timestamp not null,--Дата и время вылета (факт)
    arrival_dt timestamp not null,--Дата и время прилета (факт)
    departure_delay int null,--Задержка вылета (разница между фактической и запланированной датой в секундах)
    --EXTRACT(EPOCH FROM  f.actual_departure - f.scheduled_departure) as delay,
    arrival_delay int null,--Задержка прилета (разница между фактической и запланированной датой в секундах)  
    price float8--Стоимость
);

DROP TABLE DWH_FLIGHTS.Reject_Fact_Flight ;

CREATE TABLE DWH_FLIGHTS.Reject_Fact_Flight (
    passenger_id varchar(100) null,--пассажир
    flight_id varchar(100) null, 
    flight_no varchar(100) null,
    actual_departure timestamp null,--вылет
    actual_arrival timestamp null, --прилет    
    departure_delay int null, --Задержка вылета
    arrival_delay int null,--Задержка прилета
    aircraft_code varchar(100) null, --самолет
    departure_airport varchar(100) null,--Аэропорт вылета
    arrival_airport varchar(100) null, --Аэропорт прилета
    tarif varchar(100) null,
    amount numeric(10,2) null	
);


