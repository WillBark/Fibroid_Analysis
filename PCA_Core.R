CBF_PCA <- function(data, groups, useLabels = FALSE, labels = "", pcs = c(1, 2), type = 'scores', scale = TRUE, legendName = "Treatment") {
  
  # This vector calculates the colors needed based on the number of groups
  colores <- rainbow(length(unique(groups)))
  
  # Perform PCA
  pc <- if (scale) {
    prcomp(data, scale = TRUE)
  } else {
    prcomp(data)
  }
  
  if (type == 'scores') {
    # If labels are not provided or incorrectly given, use row names
    if (useLabels & length(labels) != nrow(data)) {
      warning("The labels not given or given incorrectly. Using rownames.")
      labels <- rownames(data)
    }
    
    # Flip PC1 or PC2 if necessary to match the desired orientation
    pcdf <- data.frame(pc1 = -pc$x[, pcs[1]], pc2 = -pc$x[, pcs[2]], labels = labels)  # Negate both to flip the plot
    
    perc_accounted <- summary(pc)$importance[2, pcs] * 100
    
    p <- ggplot(data = pcdf, aes(x = pc1, y = pc2)) + 
      geom_point(aes(fill = groups), colour = "black", size = 5.5, pch = 21) +
      scale_fill_manual(values = colores, name = legendName)
    
    if (useLabels) {
      p <- p + geom_text_repel(aes(label = labels))
    }
    
    p <- p + 
      xlab(paste("PC", pcs[1], " (", round(perc_accounted[1], 2), "%)", sep = "")) +
      ylab(paste("PC", pcs[2], " (", round(perc_accounted[2], 2), "%)", sep = "")) +
      theme_bw(base_size = 20) +
      theme(legend.position = "bottom")
    
    p
    
  } else if (type == 'loadings') {
    # Handling loadings plot if specified
    if (useLabels & length(labels) != nrow(pc$rotation)) {
      warning("Loadings labels not given or given incorrectly. Using the column names.")
      labels <- colnames(data)
    }
    
    pcdf <- data.frame(load1 = pc$rotation[, pcs[1]], load2 = pc$rotation[, pcs[2]], var = labels)
    
    p <- ggplot(data = pcdf, aes(x = load1, y = load2)) + geom_point()
    
    if (useLabels) {
      p <- p + geom_text_repel(aes(label = labels))
    }
    
    p <- p +
      xlab(paste("Loadings for PC", pcs[1], sep = "")) +
      ylab(paste("Loadings for PC", pcs[2], sep = "")) +
      ggtitle("PCA loadings plot") +
      theme_bw(base_size = 20)
    p
    
  } else if (type == 'varAcc') {
    # Handling variance accounted for plot
    perc_accounted <- (pc$sdev / sum(pc$sdev) * 100)
    perc_with_cumsum <- data.frame(pc = as.factor(1:length(perc_accounted)),
                                   perc_acc = perc_accounted,
                                   perc_cumsum = cumsum(perc_accounted))
    p <- ggplot(data = perc_with_cumsum, aes(x = pc, y = perc_cumsum)) +
      geom_bar(stat = 'identity', col = 'black', fill = 'white') +
      geom_hline(yintercept = 95, col = 'red') +
      geom_hline(yintercept = 0, col = 'black') +
      xlab('PC') +
      ylab('% Variance') +
      ggtitle('% Variance accounted for by principal components') +
      theme(legend.position = "none", legend.text = element_text(size = 10)) + 
      guides(color = guide_legend(override.aes = list(size = 10), nrow = 3, byrow = TRUE), text = FALSE)
    print(p)
    
  } else {
    cat(sprintf("\nError: no type %s", type))
  }
  
  return(p)
}


