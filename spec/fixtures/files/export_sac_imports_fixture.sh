#!/bin/bash

# Convert the ODS file to CSV
soffice --convert-to csv:"Text - txt - csv (StarCalc)":44,34,UTF8,1,,0,true,true,false,false,false,-1 --outdir ./sac_imports_src sac_imports_fixture.ods

# Navigate to the output directory
cd sac_imports_src

# Loop over the generated CSV files
for file in sac_imports_fixture-*.csv; do
    # Extract the sheet name
    sheet_name=$(echo "$file" | cut -d'-' -f2 | cut -d'.' -f1)

    # Rename the file to [sheet_name]_[original_file_name].csv
    mv "$file" "${sheet_name}_fixture.csv"
done
