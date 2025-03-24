# mgga-postanalysis (v. 1.01)
R code script to adjust values of CH4 and CO2 measured via MGGA based on a linear increase in gas concentration in a closed system (like an injection loop). The gas concentration is measured via an injection loop attached to MGGA; either low change from baseline (~15ppb) or too low in general (&lt; atmospheric levels, equal to &lt; 1.9ppm) need to be slope-corrected. Samples are processed in parallel, visualized in graphic outputs, and averages of both, unadjusted and adjusted values and their differences are saved in individual files for CH4 and CO2. 

DISCLAIMER: Always mind your data nature and check your results. 
Please, let me know how the code has worked for you! Good luck!

Only the last 20 points of baseline data are used for a linear model. *crucial part: identifying the 'baseline_end' point (BEFORE sample injection but as-close-as possible).
Sample data [period: 'sample_start' - 'sample_end'] are slope-adjusted, and the highest 20-point window is averaged (both adjusted and unadjusted). *crucial part: the 'sample_end' time, only if data points AFTER the sample period are HIGHER than sample points.
--> Check for the correct times using graphic outputs; adjust times in csv file when necessary. 

Important: 20-point windows are a good size for gas concentration measurements taken by MGGA every 1 second; adjust your measurement settings OR consider narrower windows (e.g. if you have a 3s average, consider a 7-point window).

Input files (available as example): "sample-period-times.csv", "mgga-time-ch4-co2.csv" # ..note that some CH4 concentration are above atmospheric

# Graphic output for CO2
Note that carbon dioxide concentration is affected by dilution, therefore, you need to use slope correction. 

![2821_c_CO2_Concentration](https://github.com/veverusha/mgga-postanalysis/assets/54019396/1a502ce1-f325-47db-b9c1-b5987d1bbb2c)

# Graphic output for CH4 
Note the methane concentration is above atmospheric values; the change is > 15ppb and dilution won't affect your unadjusted values -> those (and their difference) are your result.

![2826_b_CH4_Concentration](https://github.com/veverusha/mgga-postanalysis/assets/54019396/99268b3e-af69-4729-8e32-6e01d387c02c)

## EXAMPLES
# major errors in period time -- those will affect your output values
1] 'baseline_end' time is too late -> already logging sample being injected; also 'sample_start' may be shifted back a few points (seconds)

![image](https://github.com/veverusha/mgga-postanalysis/assets/54019396/a8b36130-53dd-427d-99c3-ff764b0fb13b)

2] 'sample_end' too late and gas concentration gets higher than during the sample period log

![image](https://github.com/veverusha/mgga-postanalysis/assets/54019396/7fca2453-f149-4a58-8189-23b4d0d59170)

# minor errors in period time -- those won't affect your output values

1] 'baseline_start' too early (here, it logs the injection loop being flushed with pure nitrogen gas).
note: only the last 20 points (or as much as you want to) are being considered for linear model calculation, therefore, anything before that is not relevant.

![image](https://github.com/veverusha/mgga-postanalysis/assets/54019396/29dbf813-a5ff-47f4-bddf-6311e1c6a5cb)

2] 'sample_end' too late but gas concentration gets lower than during the sample period log

![image](https://github.com/veverusha/mgga-postanalysis/assets/54019396/d6006b9d-e738-46ed-9fb6-f85497bc8e42)
