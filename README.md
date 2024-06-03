# mgga-postanalysis
Script for R to slope-correct values of CH4 and CO2 measured via MGGA. The gas concentration is measured via an injection loop attached to MGGA; either low change from baseline (~15ppb) or too low in general (&lt; atmospheric levels, equal to &lt; 1.9ppm) need to be slope-corrected. Samples are processed in parallel. 

The last 20 points of baseline data are used for a linear model -> data points are adjusted accordingly. *crucial part: identifying the 'baseline_end' point (BEFORE sample injection but as-close-as possible).
All sample data [period: 'sample_start' - 'sample_end'] are slope-adjusted (green line); the highest 20-point window is averaged (both adjusted and unadjusted). *crucial part: the 'sample_end' time, only if data points AFTER the sample period are HIGHER than sample points.
--> Check crucial parts using graphic output for each sample and gas; make adjustments in csv sample periods time when necessary.

Input files (available as example): "sample-period-times.csv", "mgga-time-ch4-co2.csv" # ..note that some CH4 concentration are above atmospheric ;-)

# Graphic output for CO2
Note that carbon dioxide concentration is affected by dilution, therefore, you need to use slope-correction.
![2821_c_CO2_Concentration](https://github.com/veverusha/mgga-postanalysis/assets/54019396/1a502ce1-f325-47db-b9c1-b5987d1bbb2c)

# Graphic output for CH4 
Note the methane concentration is above atmospheric values; change is > 15ppb and dilution won't affect your unadjusted values -> those and their difference is your result.
![2826_b_CH4_Concentration](https://github.com/veverusha/mgga-postanalysis/assets/54019396/99268b3e-af69-4729-8e32-6e01d387c02c)
