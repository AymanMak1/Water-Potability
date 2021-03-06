#L'installation des packages n�cessaires

install.packages("FSelector")
install.packages("party")
install.packages("rpart.plot")
install.packages("data.tree")
install.packages("ggthemes")
install.packages("rattle")

#Le chargement des librairies n�cessaire

library(FSelector)
library(rpart)
library(caret)
library(rpart.plot)
library(data.tree)
library(dplyr)
library(caTools)

library(randomForest)
library(psych)
library(pROC)
library(Amelia)

library(ggplot2)
library(plotly)
library(ggthemes)

#library(rattle)


#Importation et �tude des donn�es

# Importer les donn�e qui ont dans le fichier water_potability.csv qui est dans la m�me r�pertoire
data <- read.csv("./water_potability.csv")

# les premi�res observations des donn�es
head(data)

# les derni�res observations des donn�es
tail(data)

# La structure des attributs
str(data)

# Statiques de bases sur l'ensemble des attributs
summary(data)
#describe(data)

# Les valeurs non-observ�s pour chaque attribut
missmap(data)

table(data$Potability)


#Pre-Processing, correction et nettoyage des donn�es

# generer une liste des indexes al�atoires
shuffle_index <- sample(1:nrow(data))

# On va utiliser ses indexes pour m�langer les donn�e
data <- data[shuffle_index, ]

# Conversion de la variable cible d'une forme num�rique au forme cat�gorielle 
data <- mutate(data, Potability = factor(Potability, levels = c(0, 1), labels = c('No', 'Yes')))

# Supprimer tout les observation avec des valeurs manquantes
data <- na.omit(data)
glimpse(data)


#Divise les donn�es entre donn�es d'apprentissage et donn�es de test

# Les donn�es sont divis�es : 80% d'apprentissage, et 20% de test
set.seed(123)
sample = sample.split(data$Potability, SplitRatio = .80)

# Donn�es d'apprentissage
train_data = subset(data, sample==TRUE)

# Donn�es de test
test_data = subset(data, sample==FALSE)

# Pourcentage de potabilit� dans les donn�es d'apprentissage et les donn�es de test
prop.table(table(train_data$Potability))
prop.table(table(test_data$Potability))


#Etudes d'ensemble des attributs des donn�es

# Importance des attributs
# L'utilisation des for�ts al�atoires juste pour visualiser l'importance de chaque variable

rf_tmp <- randomForest(Potability ~ ., 
                       data=train_data, ntree=1000, 
                       keep.forest=FALSE, 
                       importance=TRUE)

# varImpPlot(rf_tmp, main = "Importance des variables")
# importance(rf_tmp)

# GGploot Plots
 
feat_imp_df <- importance(rf_tmp) %>% 
    data.frame() %>% 
    mutate(feature = row.names(.)) 

# Feature Importance Graph | MeanDecreaseAccuracy

importanceAccuracyGraph <- ggplot(feat_imp_df, aes(x = reorder(feature, MeanDecreaseAccuracy), y = MeanDecreaseAccuracy)) +
    geom_point() +
    coord_flip() +
    theme_classic() +
    labs(
      x     = "Feature",
      y     = "Importance",
      title = "Feature Importance Graph by MeanDecreaseAccuracy",
      color="Feature"
    )

ggplotly(importanceAccuracyGraph)


# Feature Importance Graph | MeanDecreaseGini

importanceGiniGraph <- ggplot(feat_imp_df, aes(x = reorder(feature, MeanDecreaseGini), y = MeanDecreaseGini)) +
    geom_point() +
    coord_flip() +
    theme_classic() +
    labs(
      x     = "Feature",
      y     = "Importance",
      title = "Feature Importance Graph by MeanDecreaseGini",
      color="Feature"
    )

ggplotly(importanceGiniGraph)


#Cr�ation du mod�le d'arbre de d�cision avec les donn�es d'apprentissage

# Cr�attion du classifieur sur les donn�e d'apprentissage
tree <- rpart(Potability ~.,
              data = train_data, 
              method="class")


#Pr�diction avec l'arbre de d�cision sur les donn�e de test

# Pr�diction sur les donn�es de test
tree.Potability.predicted <- predict(tree, test_data, type='class')

# Calculer l'erreur de la pr�diction sur les donn�es de test
tab <- table(tree.Potability.predicted, test_data$Potability)
paste("Erreur sur le test_data :", round(1 - sum(diag(tab)) / sum(tab), digits = 2), "%")
cat("\n")

# G�n�rer la courbe ROC
#roc(test_data$Potability,
#    as.numeric(tree.Potability.predicted), 
#   plot=TRUE, legacy.axes=TRUE, percent=TRUE, print.auc=TRUE)

# Evaluer le mod�le avec la matrice de confusion
confusionMatrix(tree.Potability.predicted,test_data$Potability)


#Visualisation de l'arbre de d�cision graphiquement

# Visualisation de l'arbre de d�cision
prp(tree)
# library rattle pour ce type de plots
fancyRpartPlot(tree ,yesno=2,split.col="black",nn.col="black", 
               caption="",palette="Set3",branch.col="black")

#print(tree2)
#plot(tree2)


# Cr�ation d'une matrice de confusion manuellement pour comparer le pourcentage de succ�e et pourcentage d'�chec
prediction <- predict(tree, test_data, type = 'class')

table_mat <- table(prediction, reference = test_data$Potability)
table_mat

# Calcul de l'efficacit� du mod�le
accuracy_test_data <- sum(diag(table_mat)) / sum(table_mat)
cat("\n")
print(paste('Accuracy for test_data', round(accuracy_test_data * 100, digits = 2), "%"))