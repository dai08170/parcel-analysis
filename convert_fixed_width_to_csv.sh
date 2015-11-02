#!/usr/bin/bash
# Called: $ convert_fixed_width_to_csv.sh data_dict.csv field_widths_index fw_data_file.csv
# NOTE: Uses ">" as the delimiter because this is one of the very few characters available with these data...

# e.g., python field_widths.py ~/Downloads/RealtyTrac/REALTYTRAC_DLP_3.0_Recorder_Layout.csv 4
# As the index of the field length colum is 4
FIELDWIDTHS=$(python field_widths.py $1 $2)

# First part parses fixed width; second part strips extra whitespace; third part removes backslashes...
gawk '$1=$1' FIELDWIDTHS="$FIELDWIDTHS" OFS=">" $3 | sed 's/ *> */>/g' | sed 's|\\||g'

# For quoted data (and semicolon delimiters):
# First part parses fixed width; second part quotes fields; third part strips extra whitespace
# gawk '$1=$1' FIELDWIDTHS="$FIELDWIDTHS" OFS=";" $3 | sed -e 's/^\|$/"/g' -e 's/;/","/g' | sed 's/ *\",\" */\",\"/g'