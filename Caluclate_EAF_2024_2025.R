library(lubridate)
library(dplyr)
library(tidyr)
library(here)

rm(list = ls())
script_path <- dirname(sys.frame(1)$ofile)
setwd(script_path)

Sys.setlocale("LC_TIME", "C")

FinacialYear <- "2024/2025"

reconciled_load <- read.csv("Data/Reconciled_Offtake.csv") %>%
  transmute(TradingDate = as.Date(TradingDate,'%Y-%m-%d'),
            TradingPeriod = TradingPeriodNumber,
            Node = PointOfConnectionCode, MWh)

CO2_average_price <- read.csv("Data/CO2_Average_Price.csv") %>%
  filter(Year==FinacialYear) %>% select(Year,CO2_Price_Average)

physical_trading_nodes <- reconciled_load %>% select(Node) %>% unique() %>% arrange(Node)


read_all_csv <- function(folderpath = "C:/Simulations/EAF_2025/vSPD_5.0.5/Output/Done/",
                         scenario = "BaseCase", 
                         filetype = "PublishedEnergyPrices_TP"){
  filelist <- list.files(path = folderpath,
                         pattern = paste0("^",scenario,".*\\",filetype,".csv$"),
                         full.names = T, recursive = T)
  
  # read all csv into dataframe
  df_list <- lapply(filelist, read.csv)
  df <- do.call(rbind, df_list)
  df <- na.omit(df)
  
  df <- df %>% filter(Pnodename %in% physical_trading_nodes$Node) %>%
    separate(DateTime, into = c("TradingDate","TradingTime"), sep = " ") %>%
    mutate(TradingDate = as.Date(TradingDate,'%d-%b-%Y')) %>%
    mutate(TradingPeriod = gsub(x=TradingPeriod,pattern="TP",replacement="")) %>%
    mutate(TradingPeriod = as.integer(TradingPeriod)) %>% 
    transmute(TradingDate,TradingTime,TradingPeriod,
              Node = Pnodename,Price = vSPDDollarsPerMegawattHour)
  return(df)
}

price_base     <- read_all_csv(scenario = "BaseCase")
price_counter  <- read_all_csv(scenario = "CounterFactual_")
price_counter1 <- read_all_csv(scenario = "CounterFactual1_")
price_counter2 <- read_all_csv(scenario = "CounterFactual2_")


if (F) {
months <- format(seq(as.Date("2024-07-01"), as.Date("2025-05-01"), by="month"),"%Y%m")
for (m in months){
  
  price_path <- paste0("vSPD_5.0.5/Output/Basecase_", m ,"/Basecase_",m,"_PublishedEnergyPrices_TP.csv")
  df_base <- read.csv(price_path) %>%
    filter(Pnodename %in% physical_trading_nodes$Node) %>%
    separate(DateTime, into = c("TradingDate","TradingTime"), sep = " ") %>%
    mutate(TradingDate = as.Date(TradingDate,'%d-%b-%Y')) %>%
    mutate(TradingPeriod = gsub(x=TradingPeriod,pattern="TP",replacement="")) %>%
    mutate(TradingPeriod = as.integer(TradingPeriod)) %>% 
    transmute(TradingDate,TradingTime,TradingPeriod,
              Node = Pnodename,Price = vSPDDollarsPerMegawattHour)
  
  if (exists("price_base")) {
    price_base <- rbind(price_base,df_base)
  } else {
    price_base <- df_base
  }
  
  
  price_path <- paste0("vSPD_5.0.5/Output/CounterFactual_", m ,"/CounterFactual_",m,"_PublishedEnergyPrices_TP.csv")
  df_cntr <- read.csv(price_path) %>%
    filter(Pnodename %in% physical_trading_nodes$Node) %>%
    separate(DateTime, into = c("TradingDate","TradingTime"), sep = " ") %>%
    mutate(TradingDate = as.Date(TradingDate,'%d-%b-%Y')) %>%
    mutate(TradingPeriod = gsub(x=TradingPeriod,pattern="TP",replacement="")) %>%
    mutate(TradingPeriod = as.integer(TradingPeriod)) %>% 
    transmute(TradingDate,TradingTime,TradingPeriod,
              Node = Pnodename,Price = vSPDDollarsPerMegawattHour)
  
  if (exists("price_counter")) {
    price_counter <- rbind(price_counter,df_cntr)
  } else {
    price_counter <- df_cntr
  }
  
  
  
  price_path <- paste0("vSPD_5.0.5/Output/CounterFactual1_", m ,"/CounterFactual1_",m,"_PublishedEnergyPrices_TP.csv")
  df_cntr1 <- read.csv(price_path) %>%
    filter(Pnodename %in% physical_trading_nodes$Node) %>%
    separate(DateTime, into = c("TradingDate","TradingTime"), sep = " ") %>%
    mutate(TradingDate = as.Date(TradingDate,'%d-%b-%Y')) %>%
    mutate(TradingPeriod = gsub(x=TradingPeriod,pattern="TP",replacement="")) %>%
    mutate(TradingPeriod = as.integer(TradingPeriod)) %>% 
    transmute(TradingDate,TradingTime,TradingPeriod,
              Node = Pnodename,Price = vSPDDollarsPerMegawattHour)
  
  if (exists("price_counter1")) {
    price_counter1 <- rbind(price_counter1,df_cntr1)
  } else {
    price_counter1 <- df_cntr1
  }
  
  
  price_path <- paste0("vSPD_5.0.5/Output/CounterFactual2_", m ,"/CounterFactual2_",m,"_PublishedEnergyPrices_TP.csv")
  df_cntr2 <- read.csv(price_path) %>%
    filter(Pnodename %in% physical_trading_nodes$Node) %>%
    separate(DateTime, into = c("TradingDate","TradingTime"), sep = " ") %>%
    mutate(TradingDate = as.Date(TradingDate,'%d-%b-%Y')) %>%
    mutate(TradingPeriod = gsub(x=TradingPeriod,pattern="TP",replacement="")) %>%
    mutate(TradingPeriod = as.integer(TradingPeriod)) %>% 
    transmute(TradingDate,TradingTime,TradingPeriod,
              Node = Pnodename,Price = vSPDDollarsPerMegawattHour)
  
  if (exists("price_counter2")) {
    price_counter2 <- rbind(price_counter2,df_cntr2)
  } else {
    price_counter2 <- df_cntr2
  }

}
} # Old code, not used

DF <- reconciled_load %>% 
  inner_join(price_base, by = c('TradingDate','TradingPeriod','Node')) %>%
  rename(Price_Base = Price) %>%
  inner_join(price_counter, by = c('TradingDate','TradingPeriod','TradingTime','Node')) %>%
  rename(Price_Counter = Price) %>%
  inner_join(price_counter1, by = c('TradingDate','TradingPeriod','TradingTime','Node')) %>%
  rename(Price_Counter1 = Price) %>%
  inner_join(price_counter2, by = c('TradingDate','TradingPeriod','TradingTime','Node')) %>%
  rename(Price_Counter2 = Price) 



DF1 <- DF %>% filter(!( is.na(MWh) | is.na(Price_Base) | is.na(Price_Counter) | is.na(Price_Counter1) | is.na(Price_Counter2) ))


results <- DF1 %>% summarise(Demand_MWh = sum(MWh), 
                            Cost_Base = sum(Price_Base * MWh),
                            Cost_Counter = sum(Price_Counter * MWh),
                            Cost_Counter1 = sum(Price_Counter1 * MWh),
                            Cost_Counter2 = sum(Price_Counter2 * MWh),
                            ) %>% 
  mutate(LWAP_Base = round(Cost_Base/ Demand_MWh,2),
         LWAP_Counter = round(Cost_Counter/ Demand_MWh, 2),
         LWAP_Counter1 = round(Cost_Counter1/ Demand_MWh, 2),
         LWAP_Counter2 = round(Cost_Counter2/ Demand_MWh, 2)
         ) %>%
  transmute(Year = FinacialYear, Demand_MWh, LWAP_Base, 
            LWAP_Counter,LWAP_Counter1,LWAP_Counter2) %>% 
  merge(CO2_average_price, by = 'Year',all = T) %>%
  mutate(Price_UpLift = LWAP_Base - LWAP_Counter) %>%
  mutate(EAF = round(Price_UpLift/CO2_Price_Average, 3)) %>%
  
  mutate(Price_UpLift1 = LWAP_Base - LWAP_Counter1) %>%
  mutate(Price_UpLift2 = LWAP_Base - LWAP_Counter2) %>%
  mutate(EAF1 = round(Price_UpLift1/CO2_Price_Average, 3)) %>%
  mutate(EAF2 = round(Price_UpLift2/CO2_Price_Average, 3))
  

write.csv(results, paste0("TestResults_",
                          gsub(x = FinacialYear,pattern = "/",replacement = "_"),
                          "_",format(Sys.time(),"%Y%m%d%H%M"),".csv"),row.names = F)


# Check period with missing prices and rerun using different cplex option
DF2 <- reconciled_load %>% 
  left_join(price_base, by = c('TradingDate','TradingPeriod','Node')) %>%
  rename(Price_Base = Price) %>%
  left_join(price_counter, by = c('TradingDate','TradingPeriod','TradingTime','Node')) %>%
  rename(Price_Counter = Price) %>%
  left_join(price_counter1, by = c('TradingDate','TradingPeriod','TradingTime','Node')) %>%
  rename(Price_Counter1 = Price) %>%
  left_join(price_counter2, by = c('TradingDate','TradingPeriod','TradingTime','Node')) %>%
  rename(Price_Counter2 = Price) %>%
  filter(is.na(Price_Base) | is.na(Price_Counter)| is.na(Price_Counter1)| is.na(Price_Counter2)) %>%
  arrange(TradingDate,TradingPeriod, Node)

if (F) {
  missing_basecase <- filter(DF2,is.na(Price_Base)) %>% select(TradingDate,TradingPeriod,TradingTime) %>% distinct()
  
  intervals <- missing_basecase %>%
    rowwise() %>%
    do({
      start_time <- ymd_hm(paste(.$TradingDate, .$TradingTime))
      data.frame(
        Interval = toupper(format(seq(start_time, by = "5 min", length.out = 6), "%d-%b-%Y %H:%M"))
      )
    })
  write.csv(intervals,file = "vSPDtpsToSolve.inc",row.names = FALSE)
  missing_basecase <- transmute(missing_basecase, TradingDate = paste0("Pricing_",format(TradingDate,"%Y%m%d"))) %>% distinct()
  write.csv(missing_basecase,file = "vSPDfilelist.inc",row.names = FALSE)
}

if (F) {
  missing_counter <- filter(DF2, is.na(Price_Counter)) %>% select(TradingDate,TradingPeriod,TradingTime) %>% distinct()
  intervals <- missing_counter %>%
    rowwise() %>%
    do({
      start_time <- ymd_hm(paste(.$TradingDate, .$TradingTime))
      data.frame(
        Interval = toupper(format(seq(start_time, by = "5 min", length.out = 6), "%d-%b-%Y %H:%M"))
      )
    })
  write.csv(intervals,file = "vSPDtpsToSolve.inc",row.names = FALSE)
  missing_counter <- transmute(missing_counter, TradingDate = paste0("Pricing_",format(TradingDate,"%Y%m%d"))) %>% distinct()
  write.csv(missing_counter,file = "vSPDfilelist.inc",row.names = FALSE)
}

if (F) {  
  missing_counter1 <- filter(DF2,is.na(Price_Counter1)) %>% select(TradingDate,TradingPeriod,TradingTime) %>% distinct()
  intervals <- missing_counter1 %>%
    rowwise() %>%
    do({
      start_time <- ymd_hm(paste(.$TradingDate, .$TradingTime))
      data.frame(
        Interval = toupper(format(seq(start_time, by = "5 min", length.out = 6), "%d-%b-%Y %H:%M"))
      )
    })
  write.csv(intervals,file = "vSPDtpsToSolve.inc",row.names = FALSE)
  missing_counter1 <- transmute(missing_counter1, TradingDate = paste0("Pricing_",format(TradingDate,"%Y%m%d"))) %>% distinct()
  write.csv(missing_counter1,file = "vSPDfilelist.inc",row.names = FALSE)
}

if (F) {   
  missing_counter2 <- filter(DF2,is.na(Price_Counter2)) %>% select(TradingDate,TradingPeriod,TradingTime) %>% distinct()
  intervals <- missing_counter2 %>%
    rowwise() %>%
    do({
      start_time <- ymd_hm(paste(.$TradingDate, .$TradingTime))
      data.frame(
        Interval = toupper(format(seq(start_time, by = "5 min", length.out = 6), "%d-%b-%Y %H:%M"))
      )
    })
  write.csv(intervals,file = "vSPDtpsToSolve.inc",row.names = FALSE)
  missing_counter2 <- transmute(missing_counter2, TradingDate = paste0("Pricing_",format(TradingDate,"%Y%m%d"))) %>% distinct()
  write.csv(missing_counter2,file = "vSPDfilelist.inc",row.names = FALSE)
  
}
