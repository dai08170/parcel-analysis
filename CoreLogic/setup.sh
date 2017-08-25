DBNAME=corelogic
OWNER=arthur
DQ_DATA_DIR=/home/arthur/Downloads/CoreLogic
BASE_DIR=/usr/local/dev/parcel-analysis # The location of the repository
ASSESSOR_DATA_DICT=$DQ_DATA_DIR/layouts/Tax_Layout_w_Property_Level_lat_long_w_code_01262017.csv
RECORDER_DATA_DICT=$DQ_DATA_DIR/layouts/Deed_Layout_PropertyLevel_Lat_Long_11172016.csv
SCHEMA="detroit."

# Create the database
. create_db.sh $DBNAME $OWNER

# Create the record (Recorder) table
psql -d $DBNAME -c "DROP TABLE ${SCHEMA}transactions;"
python create_from_data_dict.py "${SCHEMA}transactions" $RECORDER_DATA_DICT "sr_unique_id" | sudo -u postgres psql -d $DBNAME -f -

# Create the assessment (Assessor Record) table
psql -d $DBNAME -c "DROP TABLE ${SCHEMA}assessments;"
python create_from_data_dict.py "${SCHEMA}assessments" $ASSESSOR_DATA_DICT | sudo -u postgres psql -d $DBNAME -f -

read -n 1 -p "Insert CPI tables? [Y/n] " cont
echo ""
if [ "$cont" = "Y" ]; then
    psql -h localhost -d $DBNAME -f $BASE_DIR/sql/create_CPI_inflation_adjustment_table.sql
fi

read -n 1 -p "Insert Tax Assessor data into database? [Y/n] " cont
echo ""
if [ "$cont" = "Y" ]; then
    for file in $(ls $DQ_DATA_DIR/TaxAssessor*Detroit*.txt)
    do
        # Remove leading whitespace with sed; remove null bytes with sed; remove backslash characters with tr
        # See also: https://stackoverflow.com/questions/1347646/postgres-error-on-insert-error-invalid-byte-sequence-for-encoding-utf8-0x0
        echo "Cleaning raw text input..."
        sed 's/^[ \t]*//' $file | sed 's/\x00//g' | tr '\\' ' ' > $DQ_DATA_DIR/temp1.txt
        dos2unix -n $DQ_DATA_DIR/temp1.txt $DQ_DATA_DIR/temp2.txt

        echo "Inserting data into database tables..."
        psql -d $DBNAME -c "COPY "${SCHEMA}assessments" FROM '${DQ_DATA_DIR}/temp2.txt' WITH DELIMITER '|' NULL AS '';"
        rm $DQ_DATA_DIR/temp1.txt $DQ_DATA_DIR/temp2.txt
    done

    echo "Adding primary key..."
    psql -d $DBNAME -c "ALTER TABLE ${SCHEMA}assessments ADD COLUMN pkid bigserial PRIMARY KEY;"
fi

read -n 1 -p "Insert Transacations data into database? [Y/n] " cont
echo ""
if [ "$cont" = "Y" ]; then
    for file in $(ls $DQ_DATA_DIR/Transactions*Detroit*.txt)
    do
        psql -d $DBNAME -c "COPY "${SCHEMA}transactions" FROM '${file}' WITH DELIMITER '|' NULL AS '';"
    done

    echo "Adding primary key..."
    psql -d $DBNAME -c "ALTER TABLE ${SCHEMA}assessments ADD COLUMN pkid bigserial PRIMARY KEY;"
fi
