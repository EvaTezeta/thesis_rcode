#Libraries
library(dplyr) #To use pipes/ recode composition code
library(readxl) #To import Excel files

#Import data from Excel to R
DataSL <- read_excel("DataSL.xlsx")
View(DataSL)


#Define the mapping between Composition code and DCC
mapping <- c("freshly dead- died on beach (code 2a)" = 1,
             "freshly dead (code 2a)" = 1,
             "freshly dead-slight decomposition (code 2a-2b)" = 2,
             "slight decomposition (code 2b)" = 2,
             "moderate decomposition (code 3)" = 3,
             "moderate-advanced decomposition (code 3-4)" = 4,
             "advanced decomposition (code 4)" = 5)

#Use the mapping to recode the Composition code column in DataSL
DataSL <- DataSL %>% 
  mutate(DCC = recode(`Composition code`, !!!mapping))

#Remove DCC 4 and 5
DataSL <- DataSL[!DataSL$DCC %in% c(4, 5), ]

#Reassign categories and store back in "Age Group"
DataSL$`Age Group` <- ifelse(DataSL$`Age Group` == "neonate", "N", 
                       ifelse(DataSL$`Age Group` == "juvenile", "J", 
                              ifelse(DataSL$`Age Group` == "adult", "A", DataSL$`Age Group`)))
#Change age group to factor
DataSL$`Age Group` <-as.factor(DataSL$`Age Group`)

#Round op numbers to 2 decimals
DataSL$`BT Average` <- round(DataSL$`BT Average`, 2)

View(DataSL)

#Change Findings to Death category
for (i in 1:nrow(DataSL)) {
  if (DataSL$Findings[i] == "Physical Trauma: Bottlenose Dolphin Attack")
    DataSL$`Death category`[i] <- "Interspecific interaction"
  else if (DataSL$Findings[i] == "Starvation/Hypothermia")
    DataSL$`Death category`[i] <- "Starvation"
  else if (DataSL$Findings[i] == "Physical Trauma: Anthropogenic")
    DataSL$`Death category`[i] <- "Anthropogenic trauma"
  else if (DataSL$Findings[i] == "Not Established")
    DataSL$`Death category`[i] <- "Other"
  else if (DataSL$Findings[i] == "Not established")
    DataSL$`Death category`[i] <- "Other"
  else if (DataSL$Findings[i] == "Other" || DataSL$Findings[i] == "Live Stranding")
    DataSL$`Death category`[i] <- "Other"
  else if (DataSL$Findings[i] == "Infectious Disease: Pneumonia" || 
           DataSL$Findings[i] == "Infectious Disease: Meningoencephalitis" ||
           DataSL$Findings[i] == "Infectious Disease: Other")
    DataSL$`Death category`[i] <- "Infectious disease"
  else if (DataSL$Findings[i] == "Generalised debilitation" ||
           DataSL$Findings[i] == "Physical Trauma: Other")
    DataSL$`Death category`[i] <- "Other trauma"
}

View(DataSL)


#Reassign death category for neonate porpoises - this one works!
DataSL$`Death category`[DataSL$`Age Group` == "N" & DataSL$`Death category` == "Starvation"] <- "Perinatal"

#Residuals of Age Group & Average BT change into correct Death Category for starvation/emaciation
#Model residuals for juveniles and adults separately
juvenile_lm <- lm(`BT Average` ~ `Death category`, data = subset(DataSL, `Age Group` == "J"))
juvenile_resid <- residuals(juvenile_lm)

adult_lm <- lm(`BT Average` ~ `Death category`, data = subset(DataSL, `Age Group` == "A"))
adult_resid <- residuals(adult_lm)

#Classify death category based on residual sign for juveniles
juv_idx <- which(DataSL$`Age Group` == "J" & DataSL$`Death category` == "Starvation")
DataSL$`Death category`[juv_idx] <- ifelse(juvenile_resid[juv_idx] > 0, "Starvation", "Emaciation")

#Classify death category based on residual sign for adults
ad_idx <- which(DataSL$`Age Group` == "A" & DataSL$`Death category` == "Starvation")
DataSL$`Death category`[ad_idx] <- ifelse(adult_resid[ad_idx] > 0, "Starvation", "Emaciation")

#Update remaining NA values to "Starvation/Emaciation"
DataSL$`Death category`[is.na(DataSL$`Death category`)] <- "Starvation/Emaciation"

#Change to factor - only AFTER reassigning! Otherwise won't work!
DataSL$`Death category` <- as.factor(DataSL$`Death category`)
summary(DataSL$`Death category`)



