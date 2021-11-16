library(tidyverse)
library(plotly)
library(factoextra)
library(viridis)
library(philentropy)
ahrko <- read_csv("~/Dev/20210722 AHR KO 3week motifusage table.csv")

# ggplot ----
colnames(ahrko)[5] <- "Genotype"

ahrko_gg <- ahrko[,-1] %>%
  group_by(Genotype, Motif) %>%
  summarise(Mean_percentage = mean(Percentage), sd_percentage = sd(Percentage))

ahrko_gg$Genotype  = factor(ahrko_gg$Genotype, levels=c("WT", "KO"))

ahrko_gg$Motif  = factor(ahrko_gg$Motif, levels=c(2,3,4,15,26,# Rearing
                                                  1,19,23,33, # Sitting
                                                  5,6,7,11,14,34, #Sniffing
                                                  8,12,13,18,22,24,27,28,29,31, # Truning
                                                  0,9,10,17,21,25,30,32,#walking
                                                  16,20 # Turning
))

# KO = knockout and WT = wild-type
ggplot(ahrko_gg, aes(x=Motif, y=Mean_percentage, group=Genotype)) + 
  geom_col(aes(fill=Genotype), position = "dodge") + 
  geom_errorbar(aes(ymin=Mean_percentage, ymax=Mean_percentage+sd_percentage), width=.2, position=position_dodge(1))+
  scale_fill_manual(values = c("#1e6642", "#14c877"))

# ggplot ----
# Super pair-wise T_test----
ttest_result <- list()
for (i in unique(ahrko$Motif)) {wt_vs_ko <- t.test(filter(ahrko, Motif==i, Genotype=="WT")$Percentage, 
                                                            filter(ahrko, Motif==i, Genotype=="KO")$Percentage)[["p.value"]]
result <- cbind(Motif = i, wt_vs_ko)
ttest_result[[i+1]] <- as.data.frame(result)
}
ttest_result <- do.call(rbind, ttest_result)
Ttest_result <- as.data.frame(ttest_result)
Ttest_result
write_csv(Ttest_result, "2021722 AHR KO motif_usage result.csv")

#PCA plot----
ahrko_pca <- spread(ahrko[,-c(1, 2)], key = "Motif", value = "Percentage")
ahrko_pca[is.na(ahrko_pca)] = 0

ahrko_pca_2 <- data.frame(scale(ahrko_pca[,-(1:2)]))

# Get principal component vectors using prcomp instead of princomp
ahrko_pca_2_pc <- prcomp(ahrko_pca_2)
# First 4 principal components
ahrko_pca_2_pc1_4 <- data.frame(ahrko_pca_2_pc$x[,1:4])
# Plot
plot(ahrko_pca_2_pc1_4, pch=16, col=rgb(0,0,0,0.5))

fviz_eig(ahrko_pca_2_pc)
fviz_pca_ind(ahrko_pca_2_pc,
             col.ind = "cos2", # Color by the quality of representation
             gradient.cols = c("#00AFBB", "#E7B800"),
             repel = TRUE     # Avoid text overlapping
)

group_indicator <- ahrko_pca$Genotype
group_indicator  = factor(group_indicator, levels=c("WT", "KO"))
fviz_pca_ind(ahrko_pca_2_pc,
             habillage=group_indicator,
             addEllipses = TRUE, # Concentration ellipses
             pointsize = 1.5,
             palette = c("#1e6642", "#14c877"),
             ellipse.type = "confidence",
             legend.title = "Groups",
             repel = TRUE)

#kullback leibler distances analysis----
##Define KL function:
KL_matrix <- function(input_df) {
  # input_df: a dataframe that: columns are the percentage of each motif; rows are each mice.
  # This data frame have to be clean(without any variables except probability)
  i_order <- vector()
  j_order <- vector()
  ## Create a empty matrix with size n*n. N is number of mice
  kl_result <- matrix(0, nrow=nrow(input_df), ncol=nrow(input_df)) ## nrow(input_df) is number of mice
  ## Calculate the KL value between mouse i and j.
  for (i in 1:nrow(input_df)){
    for (j in 1:nrow(input_df)){
      result <-KL(as.matrix(
        rbind(as.vector(input_df[i, 1:ncol(input_df)]), 
              as.vector(input_df[j, 1:ncol(input_df)]))),test.na = FALSE) 
      kl_result[i,j] <- result
    }
  }
  kl_result
}


# get clean matrix
KL_mx2df <- function(KL_result_matrix, Mouse_name, n_mice) {
  # input_df: a dataframe that: columns are the percentage of each motif; rows are each mice (same input with KL_matrix)
  KL_result_df <- as.data.frame(KL_result_matrix)
  colnames(KL_result_df) <- Mouse_name
  KL_result_df <- mutate(KL_result_df, Mouse_y=Mouse_name, .before = colnames(KL_result_df)[1])
  KL_result_df <- gather(KL_result_df,key =Mouse_x, value = KL_value, 2:ncol(KL_result_df))
  KL_result_df
} 


# !!!! The following code is for "motif" dataframe only
ahrko_kl<- ahrko_pca[,-c(1:2)]
# Delete Usage before 


ahrko_kl_mx <- KL_matrix(ahrko_kl)

ahrko_kl_df <- cbind(ahrko_pca[, 1:2], ahrko_kl_mx)
# Change the name of the mouse number 
colnames(ahrko_kl_df)[-(1:2)] <- as.character(ahrko_kl_df$Mouse)
## in motif_wt_kl_mx, each col is a mouse at y-axis. So it is necessary to change the name for the dataframe
ahrko_kl_df2 <- gather(ahrko_kl_df, key=Mouse_y, value=KL_result, 3:ncol(ahrko_kl_df))

###By arranging with Experiment, the order will be WT_media, WT_lacto, KO_Media, KO_Lacto
ahrko_kl_df2$Mouse <- factor(ahrko_kl_df2$Mouse, levels = as.character(unique(arrange(ahrko_kl_df2, Genotype)$Mouse)))
ahrko_kl_df2$Mouse_y <- factor(ahrko_kl_df2$Mouse_y, levels = as.character(unique(arrange(ahrko_kl_df2, Genotype)$Mouse)))

ggplot(ahrko_kl_df2, aes(x=Mouse, y=Mouse_y, fill=KL_result)) + 
  geom_tile()+
  scale_fill_viridis()
#limit = c(0,12))

## t.test of KL analysis
ko_mice <- unique(filter(ahrko_kl_df2, Genotype=="KO")$Mouse)
wt_mice <- unique(filter(ahrko_kl_df2, Genotype=="WT")$Mouse)

KO <- filter(ahrko_kl_df2, Mouse %in% ko_mice & Mouse_y %in% ko_mice)
WT <- filter(ahrko_kl_df2, Mouse %in% wt_mice & Mouse_y %in% wt_mice)
WTvsKO <- rbind(filter(ahrko_kl_df2, Mouse %in% ko_mice & Mouse_y %in% wt_mice),
                   filter(ahrko_kl_df2, Mouse %in% wt_mice & Mouse_y %in% ko_mice))

KO_gg <- mutate(summarise(KO, Mean = mean(KL_result), Sd = sd(KL_result)), Group = "KO", .before=Mean)
WT_gg <- mutate(summarise(WT, Mean = mean(KL_result), Sd = sd(KL_result)), Group = "WT", .before=Mean)
WTvsKO_gg <- mutate(summarise(WTvsKO, Mean = mean(KL_result), Sd = sd(KL_result)), Group = "WTvsKO", .before=Mean)

ggplot(rbind(WT_gg, KO_gg, WTvsKO_gg), aes(x=Group, y = Mean)) +
  geom_col(aes(fill=Group)) +
  geom_errorbar(aes(ymin=Mean, ymax=Mean+Sd), width=.2, position=position_dodge(1)) + 
  scale_fill_manual(values = c("#1e6642", "#14c877", "#0F4C3A"))

t.test(KO$KL_result, WT$KL_result)
t.test(WT$KL_result, WT$KL_result)
t.test(KO$KL_result, WT$KL_result)

