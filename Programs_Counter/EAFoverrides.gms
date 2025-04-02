*=====================================================================================
* Name:                 EAFoverrides.gms
* Function:             Code to be included in vSPDsolve to take care of input data
*                       overrides applied for EAF work
* Developed by:         Electricity Authority, New Zealand
* Source:               https://github.com/ElectricityAuthority/vSPD
*                       https://www.emi.ea.govt.nz/Tools/vSPD
* Contact:              Forum: https://www.emi.ea.govt.nz/forum/
*                       Email: emi@ea.govt.nz
* Last modified on:     1 March 2024
*
*=====================================================================================

$include vSPDsettings.inc

$OnEnd
*=========================================================================================================================
* 1. Declare all symbols required for vSPD on EMI and standalone overrides and load data from GDX
*=========================================================================================================================
Set costtype / SRMC_Carbon_Exclusive, CO2_DollarsPerMwh/;

Parameters
  co2fuelcost(dt,o,costtype)      'Override the i_tradePeriodNodeDemand parameter with dateTime data'

  co2cost(dt,o)                   'Estimated marked up price by CO2 cost $/MWh'
  srmc(dt,o)                      'Estimated fuel cost of generation $/MWh'
;

*Loading data from gdx file
$gdxin "%ovrdPath%EAF_cost.gdx"
$load co2fuelcost
$gdxin

co2cost(dt,o)  = co2fuelcost(dt,o,'CO2_DollarsPerMwh');
srmc(dt,o) = co2fuelcost(dt,o,'SRMC_Carbon_Exclusive');


$onText
In our third scenario, we assume that energy offers at or below SRMC (fuel cost only) from
thermal generators would remain as currently offered. It make more economic sense that
these at/below SRMC offers are not impacted by the ETS cost effects.
The higher-priced offers are adjusted to account for ETS cost effects but adjusted offer price
cannot be less than SRMC

Adjusted offer price  = Original offer price - (Effective NZU price * Emission intensity factor)
or
Adjusted offer price  = Original offer price - CO2 cost

$offText
* Modify the Thermal Genertion Offer Price
energyOffer(ca,dt,o,blk,'price') $ { (co2cost(dt,o) > 0) and (energyOffer(ca,dt,o,blk,'price') > srmc(dt,o)) }
        = max[srmc(dt,o), energyOffer(ca,dt,o,blk,'price') - co2cost(dt,o) ];
        


$onText
In Scenario 4, hydro generators are assumed to make corresponding adjustments to 
their offers to reflect the reduced cost of thermal generation reducing the marginal 
water value and hence their offers

In our fourth scenario, we assume that hydro energy offers below lowest thermal fuel cost (HLY5)
would remain as currently offered as these offers are unlikely to include the ETS cost effects.
The higher-priced offers are adjusted to account for ETS cost effects as discussed in Section 2.5 below

Adjusted offer price  = Original offer price - (Effective NZU price * Average emission intensity factor)
or
Adjusted offer price  = Original offer price - Average CO2 cost

Average emission intensity factor is the average amount of CO2 emissions for each 
unit of electricity produced (tonnes of CO2/MWh) by thermal generators likely to be 
marginal [These include Huntly E3P, Huntly rankine, Huntly OCGT, Mckee, TCC, Stratford, Whirinaki]
$offText

Set hydro_offers(o) 'List of hydro energy offers'
/
'ARA2201 ARA0'
'ARG1101 BRR0'
'ARI1101 ARI0'
'ARI1102 ARI0'
'ASB0661 HBK0'
'ATI2201 ATI0'
'AVI2201 AVI0'
'BEN2202 BEN0'
'BWK1101 WPI0'
'COL0661 COL0'
'CYD2201 CYD0'
'HWA1101 PTA1'
'HWA1101 PTA2'
'HWA1101 PTA3'
'HWB0331 WPI0'
'KPO1101 KPO0'
'KUM0661 KUM0'
'MAN2201 MAN0'
'MAT1101 ANI0'
'MAT1101 MAT0'
'MHO0331 MHO0'
'MTI2201 MTI0'
'NSY0331 PAE0'
'OHA2201 OHA0'
'OHB2201 OHB0'
'OHC2201 OHC0'
'OHK2201 OHK0'
'ROT1101 WHE0'
'ROX1101 ROX0'
'ROX2201 ROX0'
'RPO2201 RPO0'
'STK0661 COB0'
'TGA0331 KMI0'
'TKA0111 TKA1'
'TKB2201 TKB1'
'TKU2201 TKU0'
'TUI1101 KTW0'
'TUI1101 PRI0'
'TUI1101 TUI0'
'WKM2201 WKM0'
'WPA2201 WPA0'
'WTK0111 WTK0'
/
;

Parameter Average_CO2_cost(ca,dt);
Parameter Lowest_srmc_cost(ca,dt);

case2dt(ca,dt)          = yes $ sum[ tp $ case2dt2tp(ca,dt,tp), 1] ;  
* Modify the Hydro Genertion Offer Price
Average_CO2_cost(case2dt(ca,dt)) = sum[o ,  co2cost(dt,o) * offerParameter(ca,dt,o,'resrvGenMax')]
                                 / sum[o $ {co2cost(dt,o) * offerParameter(ca,dt,o,'resrvGenMax')}, offerParameter(ca,dt,o,'resrvGenMax')];
                                 
Lowest_srmc_cost(ca,dt) = smin[o $ srmc(dt,o), srmc(dt,o)];


energyOffer(ca,dt,hydro_offers(o),blk,'price') $ (energyOffer(ca,dt,o,blk,'price') > Lowest_srmc_cost(ca,dt))
        = max[Lowest_srmc_cost(ca,dt), energyOffer(ca,dt,o,blk,'price') - Average_CO2_cost(ca,dt) ];
       

$offEnd

