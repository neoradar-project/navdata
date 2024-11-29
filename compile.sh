rm ./navdata.db
cd ourairports-data
sqlite3 ../navdata.db <<EOS
.mode csv
.import airports.csv airports
.import runways.csv runways
.import navaids.csv navaids
EOS