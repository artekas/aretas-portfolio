# ------------------------------------------------------
# Turtle Games - Customer Loyalty Analysis
# ------------------------------------------------------

# Load packages
library(tidyverse)
library(caret)
library(skimr)
library(ggplot2)
library(dplyr)
library(syuzhet)
library(tm)
library(wordcloud)
library(RColorBrewer)

# ------------------------------------------------------
# Load and Explore the Data
# ------------------------------------------------------
df <- read_csv("/Users/aretaspetronis/Desktop/Data Analytics/Files/Course 3/assignment_files/cleaned_turtle_reviews.csv")

# View structure and basic stats
str(df)
head(df)
summary(df)
skim(df)

# Check for missing values
colSums(is.na(df))

# Rename columns for easier use
df <- df %>%
  rename(
    income = `remuneration (k£)`
  )

# Visualise key variables
ggplot(df, aes(x = loyalty_points)) +
  geom_histogram(bins = 30, fill = "steelblue", alpha = 0.7) +
  ggtitle("Distribution of Loyalty Points")

ggplot(df, aes(y = loyalty_points)) +
  geom_boxplot(fill = "orange", alpha = 0.6) +
  ggtitle("Boxplot of Loyalty Points")

ggplot(df, aes(x = spend_score, y = loyalty_points)) +
  geom_point(alpha = 0.6, color = "darkgreen") +
  ggtitle("Spending Score vs Loyalty Points")

ggplot(df, aes(x = age, y = loyalty_points)) +
  geom_point(alpha = 0.6, color = "purple") +
  ggtitle("Age vs Loyalty Points")

ggplot(df, aes(x = income, y = loyalty_points)) +
  geom_point(alpha = 0.6, color = "darkred") +
  ggtitle("Income vs Loyalty Points")

# ------------------------------------------------------
# Summary 
# ------------------------------------------------------

# The exploratory analysis of Turtle Games' customer data revealed several key insights into loyalty
# point distribution and influencing factors. Loyalty points ranged from 25 to 6847 and were heavily
# right-skewed, as seen in both the histogram and boxplot. A significant number of high-value outliers
# were present, suggesting a small segment of highly loyal customers.
# 
# Scatterplots revealed that spending score and income have strong positive relationships with loyalty
# points. Customers with higher spending scores and income levels tend to accumulate more loyalty
# points. While age also had a positive influence, the correlation was weaker and more scattered across the range.
# 
# A multiple linear regression model confirmed these observations. All three variables — age, income,
# and spending score — were statistically significant predictors (p < 0.001). The model achieved a
# strong R-squared value of 0.84, indicating that 84% of the variation in loyalty points can be explained by these variables.

# These findings suggest that loyalty programs could be optimised by focusing on customers with
# higher spending potential. Future exploration could involve segmenting customers by platform or
# education level to uncover further behavioural trends.

# ------------------------------------------------------
# Multiple Linear Regression Model
# ------------------------------------------------------

# Select features for modeling
df_model <- df %>%
  select(age, income, spend_score, loyalty_points)

# Split into training/testing sets
set.seed(42)
trainIndex <- createDataPartition(df_model$loyalty_points, p = 0.8, list = FALSE)
train <- df_model[trainIndex, ]
test <- df_model[-trainIndex, ]

# Train model
model <- lm(loyalty_points ~ age + income + spend_score, data = train)
summary(model)

# Predict on test data
test$predicted <- predict(model, newdata = test)

# Evaluate model
mse <- mean((test$predicted - test$loyalty_points)^2)
r2 <- summary(model)$r.squared
print(paste("Mean Squared Error:", mse))
print(paste("R-Squared:", r2))

# Visualise predicted vs actual
ggplot(test, aes(x = predicted, y = loyalty_points)) +
  geom_point(alpha = 0.6, color = "dodgerblue3") +
  geom_abline(slope = 1, intercept = 0, color = "red", linetype = "dashed") +
  ggtitle("Predicted vs Actual Loyalty Points") +
  xlab("Predicted Loyalty Points") +
  ylab("Actual Loyalty Points")

# Visualise regression line
ggplot(test, aes(x = spend_score, y = loyalty_points)) +
  geom_point(alpha = 0.6) +
  geom_smooth(method = "lm", se = FALSE, color = "red") +
  ggtitle("Regression Line: Spending Score vs Loyalty Points") +
  xlab("Spending Score") + ylab("Loyalty Points")

# Predict for a new customer
new_customer <- data.frame(age = 35, income = 55, spend_score = 80)
predicted_points <- predict(model, newdata = new_customer)
print(paste("Predicted Loyalty Points for new customer:", round(predicted_points)))

# ------------------------------------------------------
# Summary 
# ------------------------------------------------------

# In this module, we created a Multiple Linear Regression (MLR) model to predict the accumulation of loyalty points using
# three numeric features: age, income, and spending score.

# 1. Model Performance:
# R-squared: 0.8407
# This means that ~84% of the variability in loyalty points can be explained by the model.
# Mean Squared Error (MSE): ~264,225
# This represents the average squared difference between predicted and actual loyalty points.

# 2. Coefficient Interpretation: All three variables were statistically significant (p < 0.001):
# Spending Score had the strongest positive effect on loyalty points (~+34.49 points per unit increase).
# Income had a similar positive effect (~+33.82 points per unit).
# Age had a smaller, but still positive impact (~+11.98 points per year of age).

# 3. Visual Diagnostics:
# The Predicted vs Actual plot shows strong alignment with the ideal prediction line, supporting the model’s accuracy.
# The regression line (Spending Score vs Loyalty Points) indicates a clear linear relationship.

# 4. Practical Use:
# Using the model, we predicted that a 35-year-old customer with £55k income and a spending score of 
# 80 would earn ~2,794 loyalty points.

# This demonstrates how the model can assist the business in identifying high-value customers.

#------------------------------------------------------------------------------------------------------
# What drives loyalty? 
#------------------------------------------------------------------------------------------------------

# Fit model 
model <- lm(loyalty_points ~ age + income + spend_score, data = train)

# Data for coefficients
df_coef <- data.frame(
  Predictor = c("Spending Score", "Income", "Age"),
  Coefficient = c(34.49, 33.82, 11.98)
)

# Plot
ggplot(df_coef, aes(x = reorder(Predictor, Coefficient), y = Coefficient, fill = Predictor)) +
  geom_bar(stat = "identity", show.legend = FALSE) +
  coord_flip() +
  geom_text(aes(label = Coefficient), hjust = -0.1, size = 4.5) +
  labs(
    title = "What Drives Loyalty?",
    x = NULL,
    y = "Effect on Loyalty Points"
  ) +
  scale_fill_manual(values = c(
    "Spending Score" = "#245985",
    "Income" = "#64889a",
    "Age" = "#b5cce2"
  )) +
  theme_minimal() +
  theme(
    plot.background = element_rect(fill = "transparent", color = NA)
  )
#-------------------------------------------------------------------------------------------------
# Customer Sentiment vs Loyalty
#-------------------------------------------------------------------------------------------------


# Calculate sentiment polarity
df$polarity <- get_sentiment(df$summary, method = "syuzhet")

# Categorise sentiment
df$sentiment_group <- ifelse(df$polarity < -0.2, "Negative",
                             ifelse(df$polarity > 0.2, "Positive", "Neutral"))

# Calculate average loyalty per sentiment group
sentiment_summary <- df %>%
  group_by(sentiment_group) %>%
  summarise(avg_loyalty = mean(loyalty_points, na.rm = TRUE))

# Plot
ggplot(sentiment_summary, aes(x = sentiment_group, y = avg_loyalty, fill = sentiment_group)) +
  geom_bar(stat = "identity", show.legend = FALSE) +
  geom_text(aes(label = round(avg_loyalty)), vjust = -0.5, size = 5) +
  labs(
    title = "Customer Sentiment vs Loyalty",
    x = "Sentiment Category",
    y = "Average Loyalty Points"
  ) +
  scale_fill_manual(values = c(
    "Negative" = "#457b9d",
    "Neutral" = "#888888",
    "Positive" = "#cccccc"
  )) +
  theme_minimal() +
  theme(
    plot.background = element_rect(fill = "transparent", color = NA)
  )
#--------------------------------------------------------------------------------------------------------------
# Model Performance Summary
#--------------------------------------------------------------------------------------------------------------

# Create performance metrics data
model_metrics <- data.frame(
  metric = c("R-squared", "Mean Squared Error"),
  value = c(0.84, 264225)
)

# Plot
ggplot(model_metrics, aes(x = metric, y = value, fill = metric)) +
  geom_col(width = 0.5) +
  geom_text(aes(label = ifelse(metric == "R-squared", paste0(value * 100, "%"), round(value))),
            vjust = -0.5, size = 5) +
  scale_fill_manual(values = c("R-squared" = "#457b9d", "Mean Squared Error" = "#999999")) +
  labs(title = "Model Performance Metrics",
       x = NULL, y = NULL) +
  theme_minimal(base_size = 14) +
  theme(
    legend.position = "none",
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank()
  )
#----------------------------------------------------------------------------------------------------------
# Loyalty by age group
#----------------------------------------------------------------------------------------------------------

# Create age groups
df$age_group <- cut(df$age, breaks = c(0, 20, 30, 40, 50, 60, 100),
                    labels = c("Under 20", "21–30", "31–40", "41–50", "51–60", "60+"))

# Calculate average loyalty points per age group
age_summary <- df %>%
  group_by(age_group) %>%
  summarise(avg_loyalty = mean(loyalty_points, na.rm = TRUE))

# Plot
ggplot(age_summary, aes(x = age_group, y = avg_loyalty, fill = age_group)) +
  geom_col(width = 0.7, show.legend = FALSE) +
  geom_text(aes(label = round(avg_loyalty)), hjust = -0.1, size = 5) +
  labs(
    title = "Average Loyalty Points by Age Group",
    x = "Age Group",
    y = "Average Loyalty Points"
  ) +
  scale_fill_manual(values = c(
    "#b3cde3", "#6497b1", "#005b96", "#b2dfdb", "#80cbc4", "#4db6ac"
  )) +
  theme_minimal(base_size = 14) +
  theme(plot.background = element_rect(fill = "transparent", color = NA)) +
  coord_flip()

#-----------------------------------------------------------------------------------------------------
# Word Cloud from Customer Feedback
#-----------------------------------------------------------------------------------------------------

# Create a text corpus from the 'review' column
corpus <- Corpus(VectorSource(df$review))

# Clean the text
corpus <- corpus %>%
  tm_map(content_transformer(tolower)) %>%
  tm_map(removePunctuation) %>%
  tm_map(removeNumbers) %>%
  tm_map(removeWords, stopwords("en")) %>%
  tm_map(stripWhitespace)

# Create a term-document matrix
tdm <- TermDocumentMatrix(corpus)
matrix <- as.matrix(tdm)

# Get word frequencies
word_freqs <- sort(rowSums(matrix), decreasing = TRUE)

# Remove dominant term like “game”
word_freqs <- word_freqs[!names(word_freqs) %in% c("game")]

# Turn into dataframe
df_words <- data.frame(word = names(word_freqs), freq = word_freqs)

# Plot word cloud
set.seed(123)
wordcloud(words = df_words$word, freq = df_words$freq,
          min.freq = 2,
          max.words = 150,
          random.order = FALSE,
          rot.per = 0.1,
          colors = brewer.pal(8, "Blues"),
          scale = c(4, 0.7))  

