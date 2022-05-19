# Code written by Aditya Kakde, owner of account @Onnamission

library(tidyverse)
library(janitor)
library(caret)
library(ggpubr)
library(pROC)
library(rpart.plot)

# setting path and reading data-------------------------------------------------

print(getwd())
setwd("D:/Projects/Stroke-Prediction")
print(getwd())

df = read.csv("Dataset/stroke.csv")

View(df)
#-------------------------------------------------------------------------------


# data cleaning-----------------------------------------------------------------

data_clean = df %>%
  na_if("N/A") %>%
  na_if("Other") %>%
  na_if("Unknown") %>%
  drop_na() %>%
  subset(select=-c(id)) %>%
  janitor::clean_names()

View(data_clean)
#-------------------------------------------------------------------------------


# changing to numeric-----------------------------------------------------------

data_clean$smoking_status[data_clean$smoking_status == "smokes"] = 1

data_clean$smoking_status[data_clean$smoking_status == "formerly smoked"] = 2

data_clean$smoking_status[data_clean$smoking_status == "never smoked"] = 3

View(data_clean)


data_clean$gender[data_clean$gender == "Male"] = 1

data_clean$gender[data_clean$gender == "Female"] = 0

View(data_clean)


data_clean$ever_married[data_clean$ever_married == "Yes"] = 1

data_clean$ever_married[data_clean$ever_married == "No"] = 0

View(data_clean)


data_clean$residence_type[data_clean$residence_type == "Urban"] = 1

data_clean$residence_type[data_clean$residence_type == "Rural"] = 0

View(data_clean)


data_clean$work_type[data_clean$work_type == "children"] = 0

data_clean$work_type[data_clean$work_type == "Govt_job"] = 1

data_clean$work_type[data_clean$work_type == "Never_worked"] = 2

data_clean$work_type[data_clean$work_type == "Private"] = 3

data_clean$work_type[data_clean$work_type == "Self-employed"] = 4

View(data_clean)
#-------------------------------------------------------------------------------


# changing data type------------------------------------------------------------

sapply(data_clean, class)

data_clean$gender = as.numeric(data_clean$gender)

data_clean$age = as.numeric(data_clean$age)

data_clean$hypertension = as.numeric(data_clean$hypertension)

data_clean$heart_disease = as.numeric(data_clean$heart_disease)

data_clean$ever_married = as.numeric(data_clean$ever_married)

data_clean$work_type = as.numeric(data_clean$work_type)

data_clean$residence_type = as.numeric(data_clean$residence_type)

data_clean$avg_glucose_level = as.numeric(data_clean$avg_glucose_level)

data_clean$bmi = as.numeric(data_clean$bmi)

data_clean$smoking_status = as.numeric(data_clean$smoking_status)

data_clean$stroke = as.numeric(data_clean$stroke)

sapply(data_clean, class)
#-------------------------------------------------------------------------------


# splitting the whole dataset---------------------------------------------------

intrain = createDataPartition(y = data_clean$stroke, p = 0.8, list = FALSE)

training = data_clean[intrain,]

testing = data_clean[-intrain,]
#-------------------------------------------------------------------------------


# training SVM model------------------------------------------------------------

training[["stroke"]] = factor(training[["stroke"]]) # stroke is class parameter

model = train(stroke ~.,
              method = "rpart",
              data = training,
              trControl = trainControl(method = "repeatedcv", 
                                       number = 10, 
                                       repeats = 10, 
                                       sampling = "smote"))

print(model)

prune = prune(model$finalModel, cp = 0.016718) # prune for less complexity
printcp(prune)

rpart.plot(prune)
#-------------------------------------------------------------------------------


# prediction--------------------------------------------------------------------

prediction = predict(model, newdata = testing)

print(prediction)
#-------------------------------------------------------------------------------


# Confusion Matrix--------------------------------------------------------------

confmatrix = table(prediction, testing$stroke)

confusionMatrix(confmatrix)

fourfoldplot(confmatrix, 
             color = c("cyan", "pink"),
             conf.level = 0, 
             margin = 1, 
             main = "Confusion Matrix")
#-------------------------------------------------------------------------------


# plotting ROC Curve------------------------------------------------------------

rocobj = roc(as.numeric(testing$stroke), as.numeric(prediction))
auc = round(auc(as.numeric(testing$stroke), as.numeric(prediction)), 4)

rocobj %>%
  ggroc(colour = 'steelblue', size = 2) +
  ggtitle(paste0('ROC Curve ', '(AUC = ', auc, ')')) + 
  labs(x = "Specificity", y = "Sensitivity") +
  theme_bw() + 
  theme(plot.title = element_text(size = 60),
        axis.title.x = element_text(size = 30),
        axis.title.y = element_text(size = 30),
        axis.text.x = element_text(size = 18),
        axis.text.y = element_text(size = 18))
#-------------------------------------------------------------------------------
