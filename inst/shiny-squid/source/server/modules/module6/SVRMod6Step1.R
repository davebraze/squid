#Server functions for module 6 step 1
c(
  
    ######### Set variables #########  
    Mod6Step1updateVind <- function(input, nb.IS){
      df <- matrix(rep(0,nb.IS^2),nb.IS)
      diag(df)[1] <- input$Mod6Step1_Vi
      diag(df)[2] <- input$Mod6Step1_Vs
      return(as.data.frame(df))
    },
      # Set hidden variables
       output$Mod6Step1_hidden <- renderUI({
          list(
            numericInput("Mod6Step1_Tmax", "", Modules_VAR$Tmax$max),
            matrixInput2("Mod6Step1_Vind", "", Mod6Step1updateVind(input, nb.IS)),
            matrixInput2("Mod6Step1_B", "",data.frame(matrix(c(0,sqrt(input$Mod6Step1_Vbx),0,0),1))),
            checkboxInput("Mod6Step1_X1_state", "", value = TRUE),
            checkboxInput("Mod6Step1_X1_sto_state", "", value = TRUE),
            checkboxInput("Mod6Step1_X1_sto_shared", "", value = TRUE),
            numericInput("Mod6Step1_X1_sto_V","", 1, min = 0, max = 1, step = 0.001),
            checkboxInput("Mod6Step1_ST_ind", "", value = TRUE)
          )
        }),
 	    outputOptions(output, "Mod6Step1_hidden", suspendWhenHidden = FALSE),

    # Run simulation and return results
    Mod6Step1_output <- reactive({
      
      if(input$Mod6Step1_Run == 0) # if Run button is pressed
        return(NULL)
      
      isolate({ 
        
        updateCheckboxInput(session, "isRunning", value = TRUE)
        
        # Call app main function
        data <- squid::squidR(input, module="Mod6Step1")  
        
        LMR      <- lme4::lmer(Phenotype ~ 1 + X1 + (1|Individual) + (0+X1|Individual), data = data$sampled_data)
        FIXEF    <- lme4::fixef(LMR)
        SE.FIXEF <- arm::se.fixef(LMR)
        RANDEF   <- as.data.frame(lme4::VarCorr(LMR))$vcov
        
        data$Vi       <- round(RANDEF[1],2)
        data$Vs       <- round(RANDEF[2],2)
        data$Vr       <- round(RANDEF[3],2) 
        # data$B0        <- round(lme4::fixef(LMR)[1],2) 
        # data$B1        <- round(lme4::fixef(LMR)[2],2) 
        
        data$B1      <- round(FIXEF["X1"],2)
        data$se.B1   <- round(SE.FIXEF["X1"],2)
        data$B0      <- round(FIXEF["(Intercept)"],2)
        data$se.B0   <- round(SE.FIXEF["(Intercept)"],2)
        
        updateCheckboxInput(session, "isRunning", value = FALSE)
        
        return(data)
      })  
    }),
    
    Mod6Step1_table <- reactive({
      
      data    <- Mod6Step1_output()
      
      myTable <- data.frame(
        "True"       = c("$\\text{Fixed effects}$",
                        paste("Mean of the trait ($",EQ3$mean0,"$) =",round(input$Mod6Step1_B[1],2)),
                        paste("Population-specific slope of the environmental effect ($",NOT$mean,"$) =",round(input$Mod6Step1_B[2],2)),
                        "$\\text{Random effects}$",
                        paste("Among-individual variance in intercept ($V_",NOT$devI,"$) =",input$Mod6Step1_Vi),
                        paste("Variance due to individual-specific responses to an environmental factor (random slopes; $V_{",NOT$devS,NOT$env,"}$) =",input$Mod6Step1_Vs),
                        paste("Residual variance ($V_",NOT$residualUpper,"$) =",input$Mod6Step1_Ve)),
        "Estimated" = c("$\\text{Fixed effects}$",
                        paste("Sampled mean of the trait ($",NOT$mean,"'_0$) =",ifelse(!is.null(data),paste(data$B0,"\U00b1", data$se.B0, sep=" "),"...")),
                        paste("Estimated population-specific slope of the environmental effect ($",NOT$mean,"'$) =",ifelse(!is.null(data),paste(data$B1,"\U00b1", data$se.B1, sep=" "),"...")),
                        "$\\text{Random effects}$",
                        paste("Sampled among-individual variance in intercept ($V'_",NOT$devI,"$) = ", ifelse(!is.null(data),data$Vi,"...")),
                        paste("Variance due to individual-specific responses to an environmental factor (random slopes; $V'_{",NOT$devS,NOT$env,"}$) = ", ifelse(!is.null(data),data$Vs,"...")),
                        paste("Residual variance of sample ($V'_",NOT$residualUpper,"$) = ", ifelse(!is.null(data),data$Vr,"...")))
      )  
      
      return(getTable(myTable))
    }),
    
    # Display results (table)
    output$Mod6Step1_summary_table <- renderUI({Mod6Step1_table()}),
    
    output$Mod6Step1_plot <- renderPlot({ 
      
      data  <- Mod6Step1_output()
      
      if(!is.null(data)){
        
        print(
          ggplot2::ggplot(data = data$sampled_data, ggplot2::aes(y     = Phenotype, 
                                                           x     = X1, 
                                                           color = as.factor(Individual))) +
                  ggplot2::stat_smooth(method = "lm", se=FALSE) + 
                  ggplot2::theme(legend.position="none") + 
                  ggplot2::xlab("Environmental effect") + 
                  ggplot2::ylab("Phenotype"))
        
      }else{
        print(plot(0,type='n',ann=FALSE, xaxt = "n", yaxt = "n"))
      }
    }),
    
    output$Mod6Step1_Vi_proportion  <- renderText({paste0("(",round(input$Mod6Step1_Vi / (input$Mod6Step1_Vi + input$Mod6Step1_Vbx + input$Mod6Step1_Vs + input$Mod6Step1_Ve),2)*100,"%)")}),
    output$Mod6Step1_Ve_proportion  <- renderText({paste0("(",round(input$Mod6Step1_Ve / (input$Mod6Step1_Vi + input$Mod6Step1_Vbx + input$Mod6Step1_Vs+ input$Mod6Step1_Ve),2)*100,"%)")}),
    output$Mod6Step1_Vbx_proportion <- renderText({paste0("(",round(input$Mod6Step1_Vbx / (input$Mod6Step1_Vi + input$Mod6Step1_Vbx + input$Mod6Step1_Vs + input$Mod6Step1_Ve),2)*100,"%)")}),
    output$Mod6Step1_Vs_proportion  <- renderText({paste0("(",round(input$Mod6Step1_Vs / (input$Mod6Step1_Vi + input$Mod6Step1_Vbx + input$Mod6Step1_Vs + input$Mod6Step1_Ve),2)*100,"%)")})
    
  ) # End return