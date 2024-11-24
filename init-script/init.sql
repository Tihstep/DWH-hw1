CREATE TABLE airports (
    airport_code CHAR(3) PRIMARY KEY,
    airport_name TEXT,
    city TEXT,
    coordinates_lon DOUBLE PRECISION,
    coordinates_lat DOUBLE PRECISION,
    timezone TEXT
);

CREATE TABLE aircrafts (
    aircraft_code CHAR(3) PRIMARY KEY,
    model JSONB,
    range INTEGER
);

CREATE TABLE seats (
    aircraft_code CHAR(3),
    seat_no VARCHAR(4),
    fare_conditions VARCHAR(10),
    PRIMARY KEY (aircraft_code, seat_no),
    FOREIGN KEY (aircraft_code) REFERENCES aircrafts(aircraft_code)
);

CREATE TABLE bookings (
    book_ref CHAR(6) PRIMARY KEY,
    book_date TIMESTAMPTZ,
    total_amount NUMERIC(10, 2)
);

CREATE TABLE tickets (
    ticket_no CHAR(13) PRIMARY KEY,
    book_ref CHAR(6),
    passenger_id VARCHAR(20),
    passenger_name TEXT,
    contact_data JSONB,
    FOREIGN KEY (book_ref) REFERENCES bookings(book_ref)
);

CREATE TABLE flights (
    flight_id SERIAL PRIMARY KEY,
    flight_no CHAR(6),
    scheduled_departure TIMESTAMPTZ,
    scheduled_arrival TIMESTAMPTZ,
    departure_airport CHAR(3),
    arrival_airport CHAR(3),
    status VARCHAR(20),
    aircraft_code CHAR(3),
    actual_departure TIMESTAMPTZ,
    actual_arrival TIMESTAMPTZ,
    FOREIGN KEY (departure_airport) REFERENCES airports(airport_code),
    FOREIGN KEY (arrival_airport) REFERENCES airports(airport_code),
    FOREIGN KEY (aircraft_code) REFERENCES aircrafts(aircraft_code)
);

CREATE TABLE ticket_flights (
    ticket_no CHAR(13),
    flight_id INTEGER,
    fare_conditions NUMERIC(10, 2),
    amount NUMERIC(10, 2),
    PRIMARY KEY (ticket_no, flight_id),
    FOREIGN KEY (ticket_no) REFERENCES tickets(ticket_no),
    FOREIGN KEY (flight_id) REFERENCES flights(flight_id),
    FOREIGN KEY (ticket_no, flight_id) REFERENCES ticket_flights(ticket_no, flight_id)
);

CREATE TABLE boarding_passes (
    ticket_no CHAR(13),
    flight_id INTEGER,
    boarding_no INTEGER,
    seat_no VARCHAR(4),
    PRIMARY KEY (ticket_no, flight_id),
    FOREIGN KEY (ticket_no, flight_id) REFERENCES ticket_flights(ticket_no, flight_id)
);


INSERT INTO airports (airport_code, airport_name, city, coordinates_lon, coordinates_lat, timezone)
VALUES 
('SVO', 'Sheremetyevo Alexander S. Pushkin International Airport', 'Moscow', 55.5822, 37.2453, 'Russia/Moscow'),
('LAX', 'Los Angeles International Airport', 'Los Angeles', -118.4085, 33.9416, 'America/Los_Angeles'),
('OMS', 'Omsk Central Airport', 'Omsk', 54.5800, 73.1830, 'Russia/Omsk');

INSERT INTO aircrafts (aircraft_code, model, range)
VALUES 
('A32', '{"manufacturer": "Airbus", "type": "A320"}', 6100),
('B73', '{"manufacturer": "Boeing", "type": "737"}', 5600);

INSERT INTO seats (aircraft_code, seat_no, fare_conditions)
VALUES 
('A32', '1A', 'Economy'),
('A32', '1B', 'Business'),
('B73', '2A', 'Economy'),
('B73', '2B', 'Business');

INSERT INTO bookings (book_ref, book_date, total_amount)
VALUES 
('ABC123', '2024-10-01 12:30:00+00', 350.00),
('DEF456', '2024-10-02 14:00:00+00', 500.00);

INSERT INTO tickets (ticket_no, book_ref, passenger_id, passenger_name, contact_data)
VALUES 
('TKT001', 'ABC123', 'P12345', 'John Doe', '{"email": "john.doe@example.com", "phone": "123-456-7890"}'),
('TKT002', 'DEF456', 'P67890', 'Jane Smith', '{"email": "jane.smith@example.com", "phone": "098-765-4321"}'),
('TKT003', 'ABC123', 'P12345', 'Igor', '{"email": "Igor@example.com", "phone": "123-456-0000"}'),
('TKT004', 'ABC123', 'P67890', 'Igor', '{"email": "Igor@example.com", "phone": "123-456-0000"}'),
('TKT005', 'ABC123', 'P12345', 'Igor', '{"email": "Igor@example.com", "phone": "123-456-0000"}');

INSERT INTO flights (flight_no, scheduled_departure, scheduled_arrival, departure_airport, arrival_airport, status, aircraft_code)
VALUES 
('FL001', '2024-10-05 09:00:00+00', '2024-10-05 12:00:00+00', 'SVO', 'LAX', 'Scheduled', 'A32'),
('FL002', '2024-10-06 14:00:00+00', '2024-10-06 17:00:00+00', 'LAX', 'SVO', 'Scheduled', 'B73'),
('FL003', '2024-10-07 09:00:00+00', '2024-10-07 12:00:00+00', 'SVO', 'LAX', 'Scheduled', 'A32'),
('FL004', '2024-10-08 14:00:00+00', '2024-10-08 17:00:00+00', 'SVO', 'OMS', 'Scheduled', 'B73');

INSERT INTO ticket_flights (ticket_no, flight_id, fare_conditions, amount)
VALUES 
('TKT001', 1, 200.00, 200.00),
('TKT002', 2, 200.00, 300.00), 
('TKT003', 3, 200.00, 100.00),
('TKT004', 4, 200.00, 100.00),
('TKT005', 4, 200.00, 100.00),
('TKT005', 3, 200.00, 200.00);


INSERT INTO boarding_passes (ticket_no, flight_id, boarding_no, seat_no)
VALUES 
('TKT001', 1, 1, '1A'),
('TKT002', 2, 2, '2B');

CREATE TABLE bonus_query AS 
    WITH airport_departure_stats AS (
        SELECT 
            f.departure_airport AS airport_code,
            COUNT(DISTINCT f.flight_id) AS departure_flights_num,
            COUNT(tf.ticket_no) AS departure_psngr_num
        FROM flights f
        LEFT JOIN ticket_flights tf ON f.flight_id = tf.flight_id
        GROUP BY f.departure_airport
    ),
    airport_arrival_stats AS (
        SELECT 
            f.arrival_airport AS airport_code,
            COUNT(DISTINCT f.flight_id) AS arrival_flights_num,
            COUNT(tf.ticket_no) AS arrival_psngr_num
        FROM flights f
        LEFT JOIN ticket_flights tf ON f.flight_id = tf.flight_id
        GROUP BY f.arrival_airport
    )
    SELECT 
        COALESCE(d.airport_code, a.airport_code) AS airport_code,
        COALESCE(departure_flights_num, 0) AS departure_flights_num,
        COALESCE(departure_psngr_num, 0) AS departure_psngr_num,
        COALESCE(arrival_flights_num, 0) AS arrival_flights_num,
        COALESCE(arrival_psngr_num, 0) AS arrival_psngr_num
    FROM airport_departure_stats d
    FULL OUTER JOIN airport_arrival_stats a
    ON d.airport_code = a.airport_code
    ORDER BY airport_code;


CREATE VIEW bonus_view AS 
    WITH airport_departure_stats AS (
        SELECT 
            f.departure_airport AS airport_code,
            COUNT(DISTINCT f.flight_id) AS departure_flights_num,
            COUNT(tf.ticket_no) AS departure_psngr_num
        FROM flights f
        LEFT JOIN ticket_flights tf ON f.flight_id = tf.flight_id
        GROUP BY f.departure_airport
    ),
    airport_arrival_stats AS (
        SELECT 
            f.arrival_airport AS airport_code,
            COUNT(DISTINCT f.flight_id) AS arrival_flights_num,
            COUNT(tf.ticket_no) AS arrival_psngr_num
        FROM flights f
        LEFT JOIN ticket_flights tf ON f.flight_id = tf.flight_id
        GROUP BY f.arrival_airport
    )
    SELECT 
        COALESCE(d.airport_code, a.airport_code) AS airport_code,
        COALESCE(departure_flights_num, 0) AS departure_flights_num,
        COALESCE(departure_psngr_num, 0) AS departure_psngr_num,
        COALESCE(arrival_flights_num, 0) AS arrival_flights_num,
        COALESCE(arrival_psngr_num, 0) AS arrival_psngr_num
    FROM airport_departure_stats d
    FULL OUTER JOIN airport_arrival_stats a
    ON d.airport_code = a.airport_code
    ORDER BY airport_code;