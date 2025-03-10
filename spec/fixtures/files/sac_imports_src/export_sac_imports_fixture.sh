#!/bin/bash

# Convert the ODS file to CSV
soffice --convert-to csv:"Text - txt - csv (StarCalc)":44,34,UTF8,1,,0,true,true,false,false,false,-1 sac_imports_fixture.ods

# Loop over the generated CSV files
for file in sac_imports_fixture-*.csv; do
    # Extract the sheet name
    sheet_name=$(echo "$file" | cut -d'-' -f2 | cut -d'.' -f1)

    # Normalize and rename the file to [sheet_name]_[original_file_name].csv
    if [[ "$file" =~ WSO2 ]]; then
        ./normalize_csv.rb "$file" > "${sheet_name}_fixture.csv"
        rm "$file"
    else
        mv "$file" "${sheet_name}_fixture.csv"
    fi
done
