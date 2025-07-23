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


read_all_csv <- function(folderpath = paste0(script_path,"/Output/"),
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


DF <- reconciled_load %>% 
  inner_join(price_base, by = c('TradingDate','TradingPeriod','Node')) %>%
  rename(Price_Base = Price) %>%
  inner_join(price_counter, by = c('TradingDate','TradingPeriod','TradingTime','Node')) %>%
  rename(Price_Counter = Price)



DF1 <- DF %>% filter(!( is.na(MWh) | is.na(Price_Base) | is.na(Price_Counter) ))


results <- DF1 %>% summarise(Demand_MWh = sum(MWh), 
                            Cost_Base = sum(Price_Base * MWh),
                            Cost_Counter = sum(Price_Counter * MWh)
                            ) %>% 
  mutate(LWAP_Base = round(Cost_Base/ Demand_MWh,2),
         LWAP_Counter = round(Cost_Counter/ Demand_MWh, 2),
         ) %>%
  transmute(Year = FinacialYear, Demand_MWh, LWAP_Base,LWAP_Counter) %>% 
  merge(CO2_average_price, by = 'Year',all = T) %>%
  mutate(Price_UpLift = LWAP_Base - LWAP_Counter) %>%
  mutate(EAF = round(Price_UpLift/CO2_Price_Average, 3))
  

write.csv(results, paste0("EAF_Results_",
                          gsub(x = FinacialYear,pattern = "/",replacement = "_"),
                          "_",format(Sys.time(),"%Y%m%d%H%M"),".csv"),row.names = F)


# Check period with missing prices and rerun using different cplex option
DF2 <- reconciled_load %>% 
  left_join(price_base, by = c('TradingDate','TradingPeriod','Node')) %>%
  rename(Price_Base = Price) %>%
  left_join(price_counter, by = c('TradingDate','TradingPeriod','TradingTime','Node')) %>%
  rename(Price_Counter = Price) %>%
  filter(is.na(Price_Base) | is.na(Price_Counter)) %>%
  arrange(TradingDate,TradingPeriod, Node)

