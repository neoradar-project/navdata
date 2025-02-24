rm ./open-navdata.db
cd ourairports-data
sqlite3 ../open-navdata.db <<EOS
-- Create tables with proper types
CREATE TABLE airports (
    id INTEGER PRIMARY KEY,
    ident TEXT,
    type TEXT,
    name TEXT,
    latitude_deg REAL,
    longitude_deg REAL,
    elevation_ft INTEGER,
    continent TEXT,
    iso_country TEXT,
    iso_region TEXT,
    municipality TEXT,
    scheduled_service TEXT,
    icao_code TEXT,
    iata_code TEXT,
    gps_code TEXT,
    local_code TEXT,
    home_link TEXT,
    wikipedia_link TEXT,
    keywords TEXT
);

CREATE TABLE runways (
    id INTEGER PRIMARY KEY,
    airport_ref INTEGER,
    airport_ident TEXT,
    length_ft INTEGER,
    width_ft INTEGER,
    surface TEXT,
    lighted INTEGER,
    closed INTEGER,
    le_ident TEXT,
    le_latitude_deg REAL,
    le_longitude_deg REAL,
    le_elevation_ft INTEGER,
    le_heading_degT REAL,
    le_displaced_threshold_ft INTEGER,
    he_ident TEXT,
    he_latitude_deg REAL,
    he_longitude_deg REAL,
    he_elevation_ft INTEGER,
    he_heading_degT REAL,
    he_displaced_threshold_ft INTEGER
);

CREATE TABLE navaids (
    id INTEGER PRIMARY KEY,
    filename TEXT,
    ident TEXT,
    name TEXT,
    type TEXT,
    frequency_khz REAL,
    latitude_deg REAL,
    longitude_deg REAL,
    elevation_ft INTEGER,
    iso_country TEXT,
    dme_frequency_khz REAL,
    dme_channel REAL,
    dme_latitude_deg REAL,
    dme_longitude_deg REAL,
    dme_elevation_ft INTEGER,
    slaved_variation_deg REAL,
    magnetic_variation_deg REAL,
    usageType TEXT,
    power TEXT,
    associated_airport TEXT
);

.mode csv
.import airports.csv airports
.import runways.csv runways
.import navaids.csv navaids
EOS