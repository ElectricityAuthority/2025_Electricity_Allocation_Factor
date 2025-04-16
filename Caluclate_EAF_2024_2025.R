library(lubridate)
library(dplyr)
library(tidyr)
library(here)

rm(list = ls())
script_path <- dirname(sys.frame(1)$ofile)
setwd(script_path)


reconciled_load <- read.csv("Data/Reconciled_Offtake.csv") %>%
  transmute(TradingDate = as.Date(TradingDate,'%Y-%m-%d'),
            TradingPeriod = TradingPeriodNumber,
            Node = PointOfConnectionCode, MWh)

physical_trading_nodes <- reconciled_load %>% select(Node) %>% unique() %>% arrange(Node)


months <- format(seq(as.Date("2024-07-01"), as.Date("2025-06-01"), by="month"),"%Y%m")
months <- months[1:8]
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
  
  
  price_path <- paste0("vSPD_5.0.5/Output/CounterFactual", m ,"/CounterFactual",m,"_PublishedEnergyPrices_TP.csv")
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

}


DF2 <- reconciled_load %>% 
  left_join(price_base, by = c('TradingDate','TradingPeriod','Node')) %>%
  rename(Price_Base = Price) %>%
  left_join(price_counter, by = c('TradingDate','TradingPeriod','TradingTime','Node')) %>%
  rename(Price_Counter = Price) %>%
  filter(is.na(Price_Base) | is.na(Price_Counter)) %>%
  arrange(TradingDate,TradingPeriod, Node)

DF <- reconciled_load %>% 
  inner_join(price_base, by = c('TradingDate','TradingPeriod','Node')) %>%
  rename(Price_Base = Price) %>%
  inner_join(price_counter, by = c('TradingDate','TradingPeriod','TradingTime','Node')) %>%
  rename(Price_Counter = Price) 


DF1 <- DF %>% filter(!(is.na(MWh) |is.na(Price_Base) | is.na(Price_Counter)))


results <- DF1 %>% summarise(Demand_MWh = sum(MWh), 
                            Cost_Base = sum(Price_Base * MWh),
                            Cost_Counter = sum(Price_Counter * MWh),
                            ) %>% 
  mutate(LWAP_Base = Cost_Base/ Demand_MWh,
         LWAP_Counter = Cost_Counter/ Demand_MWh
         ) %>%
  transmute(Year = '2023/2024', Demand_MWh, LWAP_Base, LWAP_Counter)

write.csv(results, paste0("TestResults_2023_2024_",format(Sys.time(),"%Y%m%d%H%M"),".csv"),row.names = F)