EAF simulation instructions
====
## Prequesite:
1. Install [GAMS](https://www.gams.com/download/) with valid licence
2. Install R (version 4.1.1)

## Steps to run Simulation:

1. Prepare Input Data
Download 365 GDX files (from 2024-07-01 to 2025-06-30) into the **Input** folder.
Files are available on the [EMI website](https://www.emi.ea.govt.nz/Wholesale/Datasets/DispatchAndPricing/GDX/) or via Azure storage (see [instructions](https://www.emi.ea.govt.nz/Forum/thread/new-access-arrangements-to-emi-datasets-retirement-of-anonymous-ftp/) 
on the EMI forum).

2. Base case simulation:
Use either:
**Run_vSPD_Base.bat**, or
**vSPD_monthly_basecase.R**

3. Counter-factual simulation:
Use either:
**Run_vSPD_Counter.bat**, or
**vSPD_monthly_counter.R**

**_Note_**: _Simulation outputs are saved in the **Output** folder by default._

4. Calculate EAF for financial year 2024/2025.
Run **Caluclate_EAF_2024_2025.R**.

**Note**: Due to data volume, not all vSPD outputs are published in this repository. For full access, contact: Tuong.Nguyen@ea.govt.nz.

### Published outputs on GitHub:
**runName_EnergyOffers_TP.csv**nbsp;nbsp;nbsp;nbsp;nbsp;nbsp;nbsp;nbsp;nbsp;nbsp;--> display energy offers in readable format.  
**runName_IslandResults_TP.csv**nbsp;nbsp;nbsp;nbsp;nbsp;nbsp;nbsp;nbsp;nbsp;--> display island summary results.  
**runName_OfferResults_TP.csv**nbsp;nbsp;nbsp;nbsp;nbsp;nbsp;nbsp;nbsp;nbsp;nbsp;--> display cleared generation/reserve results.  
**runName_PublishedEnergyPrices_TP.csv**nbsp;--> display trading period final prices.  

### Other available outputs (on request):
runName_BidResults_TP.csv              
runName_BranchResults_TP.csv
runName_BrConstraintResults_TP.csv    
runName_BusResults_TP.csv
runName_MNodeConstraintResults_TP.csv
runName_NodeResults_TP.csv
runName_PublishedReservePrices_TP.csv
runName_ReserveResults_TP.csv
runName_RiskResults_TP.csv
runName_SummaryResults_TP.csv
