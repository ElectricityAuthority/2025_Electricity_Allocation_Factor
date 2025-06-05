library(yaml)
library(AzureStor)
library(tidyr)
library(dplyr)

rm(list= ls())
current_directory <- getwd()
try(
  {current_file <- sys.frame(1)$ofile  # Ignore errors
  current_directory <- dirname(current_file)
  },
  silent = TRUE
)
setwd(current_directory)
config <- yaml::read_yaml("C:/vSPD/config.yml")

vSPDinputfolder   <- "C:/Simulations/EAF_2025/vSPD_5.0.5/Input/Pricing/"
vSPDoutputfolder  <- "C:/Simulations/EAF_2025/vSPD_5.0.5/Output/"
vSPDprogramfolder <- paste0(current_directory,'/Programs_Counter2/')

storage_account_name <- config$emidatasetsprd$storage_account_name
storage_account_key <- config$emidatasetsprd$storage_account_key
containername <- config$emidatasetsprd$container_name

# Create a connection to your emidatasetdev/public container
endpoint             <- paste0("https://", storage_account_name, ".blob.core.windows.net")
blobenpoint          <- blob_endpoint(endpoint = endpoint, key = storage_account_key)
emidataset_container <- blob_container(endpoint = blobenpoint, name = containername)

##### Functions ####
createListInc <- function(gdxlist, Incfolder = "Programs") {
  fileConn <- file(paste0(Incfolder,'/vSPDfileList.inc'))
  writeLines(c("/",paste0("'",gdxlist,"'"),"/"),con = fileConn)
  close(fileConn)
}

createvSPDSettingInc <- function(runName, opMode, ovrdfile = "''",dailymode = 1,
                                 Inputfolder = "'%system.fp%..\\Input\\'" ,
                                 Outputfolder = "'%system.fp%..\\Output\\'" ,
                                 Ovrdfolder = "'%system.fp%..\\Override\\'" ,
                                 Incfolder = "Programs") {
  
  fileConn <- file(paste0(Incfolder,'/vSPDsettings.inc'))
  
  writeLines(c("*+++ vSPD settings +++",
               "$inlinecom ## ##",
               "$eolcom !",
               "",
               "*+++ Paths +++",
               paste0("$setglobal runName                       ",runName),
               "",
               "$setglobal programPath                   '%system.fp%' ",
               paste0("$setglobal inputPath                     ",Inputfolder),
               paste0("$setglobal outputPath                    ",Outputfolder),
               paste0("$setglobal ovrdPath                      ",Ovrdfolder),
               "",
               paste0("$setglobal vSPDinputOvrdData             ",ovrdfile,"   !Name of override file "),
               "",
               "*+++ Model +++",
               "Scalar sequentialSolve                   / 0 / ;   ! Vectorisation: Yes <-> i_SequentialSolve: 0",
               paste0("Scalar dailymode                         / ",dailymode," / ;   ! Solving quickly by using RTD pre-calculated demand or PRSS solved initial MW"),
               "",
               "*+++ Network +++",
               "Scalar useACLossModel                    / 1 /    ;",
               "Scalar useHVDCLossModel                  / 1 /    ;",
               "Scalar useACBranchLimits                 / 1 /    ;",
               "Scalar useHVDCBranchLimits               / 1 /    ;",
               "Scalar resolveCircularBranchFlows        / 1 /    ;",
               "Scalar resolveHVDCNonPhysicalLosses      / 1 /    ;",
               "Scalar resolveACNonPhysicalLosses        / 0 /    ;   ! Placeholder for future code development",
               "Scalar circularBranchFlowTolerance       / 1e-4 / ;",
               "Scalar nonPhysicalLossTolerance          / 1e-6 / ;",
               "Scalar useBranchFlowMIPTolerance         / 1e-6 / ;",
               "",
               "*+++ Constraints +++",
               "Scalar useReserveModel                   / 1 /    ;",
               "Scalar suppressMixedConstraint           / 0 /    ;   ! No longer used since Mixed MIP Constraints no longer exists",
               "Scalar mixedMIPtolerance                 / 1e-6 / ;   ! No longer used since Mixed MIP Constraints no longer exists",
               "",
               "*+++ Solver +++",
               "Scalar LPtimeLimit                       / 3600 / ;",
               "Scalar LPiterationLimit                  / 2000000000 / ;",
               "Scalar MIPtimeLimit                      / 3600 / ;",
               "Scalar MIPiterationLimit                 / 2000000000 / ;",
               "Scalar MIPoptimality                     / 0 / ;",
               "$setglobal Solver                          Cplex",
               "$setglobal licenseMode                     1",
               "","",
               "*+++ Various switches +++",
               paste0("$setglobal opMode                          ",opMode ,
                      "      ! DWH for data warehouse; AUD for audit; ",
                      "FTR for FTR Rental; SPD for normal SPD run; ",
                      "PVT for pivot analysis; ",
                      "DPS for demand~price sensitivity analysis")
  ),con = fileConn)
  
  close(fileConn)
}

#####

month2run <- read.csv("months2run.csv", colClasses = 'character')
for (m in month2run$MonthID) {

  tic <- Sys.time()
  print(paste0("vSPD run for month ", m))
    
  ##### Download gdx files for vSPD run #####  
  dir <- paste0('Datasets/Wholesale/DispatchAndPricing/GDX/',substr(m,1,4),'/')
  
  gdxlist <- list.files(vSPDinputfolder,pattern = paste0("Pricing_",m))
  
  listblob <- list_blobs(container = emidataset_container, dir = dir) %>% 
    mutate(gdxname = basename(name)) %>% 
    filter(startsWith(gdxname,paste0("Pricing_",m))) %>%
    filter(!(gdxname %in% gdxlist))
  
  
  # Download Pricing gdx files
  if (nrow(listblob) > 0) {
    multidownload_blob(container = emidataset_container, 
                       src = paste0(dir,listblob$gdxname), 
                       dest = paste0(vSPDinputfolder,listblob$gdxname),
                       overwrite = T)
  }
  
  gdxlist <- list.files(vSPDinputfolder,pattern = paste0("Pricing_",m))
  createListInc(gsub("\\.gdx$", "", gdxlist), Incfolder = vSPDprogramfolder)
  
  createvSPDSettingInc(runName = paste0("CounterFactual2_",m),
                       opMode = "SPD",
                       Inputfolder = paste0("'",vSPDinputfolder,"'"),
                       Outputfolder = paste0("'",vSPDoutputfolder,"'"),
                       Incfolder = vSPDprogramfolder)
  
  ##### run merge gdx, publish daily gdx and then run vSPD #####  
  if (T) {
    
    setwd(vSPDprogramfolder)
    
    system('runvSPD.bat', wait = T)
    
    setwd(current_directory)
  }
  
  
  toc <- Sys.time()
  print(paste0("vSPD run for month ",m, " completes in ", difftime(toc,tic,unit="hour"), " hours"))
  
}

