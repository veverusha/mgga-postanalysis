#### mgga-postanalysis
# Petra Klimova, 03-06-2024, ptklimova@gmail.com
# designed with: R version 4.1.1 (2021-08-10) Kick Things, ggplot2 (v. 3.4.0), data.table (v. 1.14.2)

### Script for R to slope-correct values of CH4 and CO2 measured via MGGA. The gas concentration is 
# measured via an injection loop attached to MGGA; either low change from baseline (~15ppb) or too 
# low in general (< atmospheric levels, equal to < 1.9ppm) need to be slope-corrected. Samples are 
# processed in parallel.

### The last 20 points of baseline data are used for a linear model -> data points are adjusted 
# accordingly. *crucial part: identifying the 'baseline_end' point (BEFORE sample injection but 
# as-close-as possible). All sample data [period: 'sample_start' - 'sample_end'] are slope-adjusted 
# (green line); the highest 20-point window is averaged (both adjusted and unadjusted). 
# *crucial part: the 'sample_end' time, only if data points AFTER the sample period are HIGHER than 
# sample points. --> Check crucial parts using graphic output for each sample and gas; make adjustments 
# in csv sample periods time when necessary.

### Input files (available as example): "sample-period-times.csv", "mgga-time-ch4-co2.csv" 
# ..note that some CH4 concentration are above atmospheric ;-)


# Set working directory
setwd("C:/Users/.../")

# Load necessary libraries
library(ggplot2)
library(data.table)

# Read data from file
data <- read.csv("mgga-time-ch4-co2.csv")
colnames(data) <- c('time', 'CH4', 'CO2')
head(data)

# Read the CSV file with sample periods
times_data <- fread("sample-period-times.csv")
head(times_data)
times_data

# Convert times to POSIXct format
times_data[, baseline_start := as.POSIXct(baseline_start, format = "%H:%M:%S")]
times_data[, baseline_end := as.POSIXct(baseline_end, format = "%H:%M:%S")]
times_data[, sample_start := as.POSIXct(sample_start, format = "%H:%M:%S")]
times_data[, sample_end := as.POSIXct(sample_end, format = "%H:%M:%S")]

# Create the list of periods
periods <- lapply(1:nrow(times_data), function(i) {
  list(
    baseline_start = times_data$baseline_start[i],
    baseline_end = times_data$baseline_end[i],
    sample_start = times_data$sample_start[i],
    sample_end = times_data$sample_end[i]
  )
})

# Assign names to the list elements
names(periods) <- times_data$sample_name
names(periods)

# Convert data formats
data$CH4 <- as.numeric(data$CH4)
data$CO2 <- as.numeric(data$CO2)
data$Time <- as.POSIXct(data$time, format = "%H:%M:%S")

# Initialize results lists for CH4 and CO2
results_CH4 <- list()
results_CO2 <- list()

# Process each period
for (sample_name in names(periods)) {
  period <- periods[[sample_name]]
  
  # Extract baseline and sample data
  baseline_data <- data[data$Time >= period$baseline_start & data$Time <= period$baseline_end, ]
  sample_data <- data[data$Time >= period$sample_start & data$Time <= period$sample_end, ]
  
  # Filter data to include only the relevant time period
  plot_data <- data[data$Time >= period$baseline_start & data$Time <= period$sample_end, ]
  
  # Check if baseline_data and sample_data are not empty
  if (nrow(baseline_data) > 1 && nrow(sample_data) > 1) {
    # Convert Time to numeric (seconds since start of baseline period)
    baseline_data$Elapsed_Time <- as.numeric(difftime(baseline_data$Time, period$baseline_start, units = "secs"))
    sample_data$Elapsed_Time <- as.numeric(difftime(sample_data$Time, period$baseline_start, units = "secs"))
    plot_data$Elapsed_Time <- as.numeric(difftime(plot_data$Time, period$baseline_start, units = "secs"))
    
    # Function to process each gas (CH4 and CO2)
    process_gas <- function(gas) {
      # Use only the last 20 points of baseline_data
      if (nrow(baseline_data) > 20) {
        baseline_window <- tail(baseline_data, 20)
      } else {
        baseline_window <- baseline_data
      }
      
      # Fit linear model to the last 20 points of baseline data
      baseline_model <- lm(as.formula(paste(gas, "~ Elapsed_Time")), data = baseline_window)
      baseline_slope <- coef(baseline_model)[2]
      
      # Adjust baseline and sample data using the slope
      baseline_window[[paste("Adjusted", gas, sep = "_")]] <- baseline_window[[gas]] - baseline_slope * baseline_window$Elapsed_Time
      sample_data[[paste("Adjusted", gas, sep = "_")]] <- sample_data[[gas]] - baseline_slope * sample_data$Elapsed_Time
      plot_data[[paste("Adjusted", gas, sep = "_")]] <- plot_data[[gas]] - baseline_slope * plot_data$Elapsed_Time
      
      # Calculate the average concentration in the baseline period (last 20 points, unadjusted and adjusted)
      baseline_average_unadjusted <- mean(baseline_window[[gas]])
      baseline_average_adjusted <- mean(baseline_window[[paste("Adjusted", gas, sep = "_")]])
      
      # Create a data frame to store all windows of adjusted gas
      all_windows <- data.frame()
      
      # Find 20-point window with the highest average values in sample data (adjusted)
      max_avg_window_adjusted <- NULL
      max_avg_value_adjusted <- -Inf
      
      for (i in 1:(nrow(sample_data) - 20 + 1)) {
        window_data <- sample_data[i:(i + 20 - 1), ]
        window_avg_value_adjusted <- mean(window_data[[paste("Adjusted", gas, sep = "_")]])
        
        if (window_avg_value_adjusted > max_avg_value_adjusted) {
          max_avg_value_adjusted <- window_avg_value_adjusted
          max_avg_window_adjusted <- window_data
        }
        
        # Append the current window to all_windows
        all_windows <- rbind(all_windows, window_data)
      }
      
      # Calculate the average concentration in the max average window (adjusted)
      max_window_average_adjusted <- if (!is.null(max_avg_window_adjusted)) mean(max_avg_window_adjusted[[paste("Adjusted", gas, sep = "_")]]) else NA
      
      # Find 20-point window with the highest average values in sample data (unadjusted)
      max_avg_window_unadjusted <- NULL
      max_avg_value_unadjusted <- -Inf
      
      for (i in 1:(nrow(sample_data) - 20 + 1)) {
        window_data <- sample_data[i:(i + 20 - 1), ]
        window_avg_value_unadjusted <- mean(window_data[[gas]])
        
        if (window_avg_value_unadjusted > max_avg_value_unadjusted) {
          max_avg_value_unadjusted <- window_avg_value_unadjusted
          max_avg_window_unadjusted <- window_data
        }
      }
      
      # Calculate the average concentration in the max average window (unadjusted)
      max_window_avg_unadjusted <- if (!is.null(max_avg_window_unadjusted)) mean(max_avg_window_unadjusted[[gas]]) else NA
      
      # Calculate differences
      diff_unadj <- max_window_avg_unadjusted - baseline_average_unadjusted
      diff_adj <- max_window_average_adjusted - baseline_average_adjusted
      
      # Return results
      list(
        baseline_slope = baseline_slope,
        baseline_average_unadjusted = baseline_average_unadjusted,
        baseline_average_adjusted = baseline_average_adjusted,
        max_window_average_adjusted = max_window_average_adjusted,
        max_window_avg_unadjusted = max_window_avg_unadjusted,
        diff_unadj = diff_unadj,
        diff_adj = diff_adj,
        all_windows = all_windows,
        baseline_window = baseline_window,  # Include this
        max_avg_window_adjusted = max_avg_window_adjusted,  # Include this
        max_avg_window_unadjusted = max_avg_window_unadjusted  # Include this
      )
    }
    
    # Process CH4
    result_CH4 <- process_gas("CH4")
    results_CH4[[sample_name]] <- result_CH4
    
    # Process CO2
    result_CO2 <- process_gas("CO2")
    results_CO2[[sample_name]] <- result_CO2
    
    # Create plot for current sample for CH4
    p_CH4 <- ggplot(plot_data, aes(x = Time, y = CH4)) +
      geom_line(data = plot_data, aes(color = "CH4 concentration")) +
      geom_point(data = baseline_data, aes(x = Time, y = CH4, color = "Baseline CH4"), alpha=0.8) +
      geom_point(data = sample_data, aes(x = Time, y = CH4, color = "Sample CH4"), alpha=0.8) +
      geom_line(data = result_CH4$all_windows, aes(x = Time, y = Adjusted_CH4, color = "Adjusted CH4"), alpha = 0.5) +
      geom_point(data = result_CH4$max_avg_window_adjusted, aes(x = Time, y = Adjusted_CH4, color = "Adjusted CH4 max"), alpha = 0.8) + 
      geom_line(data = result_CH4$baseline_window, aes(x = Time, y = Adjusted_CH4, color = "Baseline CH4 last 20"), alpha = 0.5) +  # Add this line
      geom_point(data = result_CH4$baseline_window, aes(x = Time, y = Adjusted_CH4, color = "Baseline CH4 last 20"), alpha = 0.8) +  # Add this line
      scale_color_manual(values = c("CH4 concentration" = "black", 
                                    "Baseline CH4" = "blue",                                    
                                    "Sample CH4" = "red", 
                                    "Adjusted CH4" = "green",
                                    "Adjusted CH4 max" = "darkgreen",
                                    "Baseline CH4 last 20" = "purple")) +  # Add this line
      labs(title = paste("CH4 Concentration Over Time for", sample_name),
           x = "Time",
           y = "CH4 Concentration (ppm)") +
      theme_minimal() +
      theme(legend.position = "bottom", legend.justification = "right") +
      guides(color = guide_legend(order = 1, 
                                  override.aes = list(linetype = c(1, 0, 0, 1, 1, 0), 
                                                      shape = c(NA, 16, 16, NA, NA, 16))))  # Add this line
    print(p_CH4)
    
    # Save plot to a file for CH4
    ggsave(paste0(sample_name, "_CH4_Concentration.png"), plot = p_CH4, width = 10, height = 6)
    
    # Create plot for current sample for CO2
    p_CO2 <- ggplot(plot_data, aes(x = Time, y = CO2)) +
      geom_line(data = plot_data, aes(color = "CO2 concentration")) +
      geom_point(data = baseline_data, aes(x = Time, y = CO2, color = "Baseline CO2"), alpha=0.8) +
      geom_point(data = sample_data, aes(x = Time, y = CO2, color = "Sample CO2"), alpha=0.8) +
      geom_line(data = result_CO2$all_windows, aes(x = Time, y = Adjusted_CO2, color = "Adjusted CO2"), alpha = 0.5) +
      geom_point(data = result_CO2$max_avg_window_adjusted, aes(x = Time, y = Adjusted_CO2, color = "Adjusted CO2 max"), alpha = 0.8) +
      geom_line(data = result_CO2$baseline_window, aes(x = Time, y = Adjusted_CO2, color = "Baseline CO2 last 20"), alpha = 0.5) +  # Add this line
      geom_point(data = result_CO2$baseline_window, aes(x = Time, y = Adjusted_CO2, color = "Baseline CO2 last 20"), alpha = 0.8) +  # Add this line
      scale_color_manual(values = c("CO2 concentration" = "black", 
                                    "Baseline CO2" = "blue", 
                                    "Sample CO2" = "red", 
                                    "Adjusted CO2" = "green",
                                    "Adjusted CO2 max" = "darkgreen",
                                    "Baseline CO2 last 20" = "purple")) +  # Add this line
      labs(title = paste("CO2 Concentration Over Time for", sample_name),
           x = "Time",
           y = "CO2 Concentration (ppm)") +
      theme_minimal() +
      theme(legend.position = "bottom", legend.justification = "right") +
      guides(color = guide_legend(order = 1, 
                                  override.aes = list(linetype = c(1, 0, 0, 1, 1, 0), 
                                                      shape = c(NA, 16, 16, NA, NA, 16))))  # Add this line
    print(p_CO2)
    
    # Save plot to a file for CO2
    ggsave(paste0(sample_name, "_CO2_Concentration.png"), plot = p_CO2, width = 10, height = 6)
  } else {
    results_CH4[[sample_name]] <- list(
      baseline_slope = NA,
      baseline_average_unadjusted = NA,
      baseline_average_adjusted = NA,
      max_window_average_adjusted = NA,
      max_window_avg_unadjusted = NA,
      diff_unadj = NA,
      diff_adj = NA
    )
    results_CO2[[sample_name]] <- list(
      baseline_slope = NA,
      baseline_average_unadjusted = NA,
      baseline_average_adjusted = NA,
      max_window_average_adjusted = NA,
      max_window_avg_unadjusted = NA,
      diff_unadj = NA,
      diff_adj = NA
    )
  }
}


# CH4 results
# Convert results to a data frame for printing
results_df_CH4 <- do.call(rbind, lapply(names(results_CH4), function(name) {
  res <- results_CH4[[name]]
  res$sample_name <- name
  res
}))
# Reorder columns for CH4
results_df_CH4 <- results_df_CH4[, c("sample_name",  "baseline_average_unadjusted", "baseline_slope","baseline_average_adjusted", 
                                     "max_window_avg_unadjusted", "max_window_average_adjusted", "diff_adj","diff_unadj")]
# Print results for CH4
print(results_df_CH4)
write.csv(results_df_CH4, "results_df_CH4.csv", row.names=FALSE)

# CO2 results
# Convert results to a data frame for printing
results_df_CO2 <- do.call(rbind, lapply(names(results_CO2), function(name) {
  res <- results_CO2[[name]]
  res$sample_name <- name
  res
}))
# Reorder columns for CO2
results_df_CO2 <- results_df_CO2[, c("sample_name",  "baseline_average_unadjusted", "baseline_slope","baseline_average_adjusted", 
                                     "max_window_avg_unadjusted", "max_window_average_adjusted", "diff_adj","diff_unadj")]
# Print results for CO2
print(results_df_CO2)
write.csv(results_df_CO2, "results_df_CO2.csv", row.names=FALSE)
