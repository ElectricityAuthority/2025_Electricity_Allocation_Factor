@echo off

REM Change to the directory where the R script is located
cd /D "%~dp0"

REM Run the R script using Rscript

title "run vSPD monthly EAF counter_factual"
"C:\Program Files\R\R-4.1.1\bin\x64\Rscript" --vanilla "vSPD_monthly_counter2.R"

pause
