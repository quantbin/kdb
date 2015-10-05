\cd /home/alex/kdb/data
\cd

loadFed:{[sym]
 system "curl -o ",sym,".csv https://research.stlouisfed.org/fred2/series/",sym,"/downloaddata/",sym,".csv";
 `DATE xkey ("DF"; enlist ",") 0:`$sym,".csv"
 };

loadQuandlGold:{[]
 system "curl -o quandl-gold.csv https://www.quandl.com/api/v3/datasets/BUNDESBANK/BBK01_WT5511.csv";
 `DATE xkey (select DATE:Date, VALUE:Value from ("DF"; enlist ",") 0:`$"quandl-gold.csv")
 };

avgByYear:{[tbl] select VALUE:avg[VALUE] by YEAR:DATE.year from tbl};

divFed:{
 select YEAR, nom%den from 
 (`YEAR xkey select YEAR, nom:VALUE from avgByYear[x]) ij 
 (`YEAR xkey select YEAR, den:VALUE from avgByYear[y])
 };

 /https://research.stlouisfed.org/fred2/tags/series?t=wages
DGS10:loadFed "DGS10";
FEDFUNDS:loadFed "FEDFUNDS";
 /Consumer Price Index for All Urban Consumers: Meats, poultry, fish, and eggs
CUSR0000SAF112:loadFed "CUSR0000SAF112";
 /Consumer Price Index for All Urban Consumers: Food and Beverages
 /https://research.stlouisfed.org/fred2/series/CPIFABSL
CPIFABSL:loadFed "CPIFABSL";
 /Consumer Price Index for All Urban Consumers: Food
CPIUFDNS:loadFed "CPIUFDNS";
 /Gold Fixing Price 10:30 A.M. (London time) in London Bullion Market, based in U.S. Dollars
 /https://research.stlouisfed.org/fred2/series/GOLDAMGBD228NLBM
GOLDAMGBD228NLBM:loadFed "GOLDAMGBD228NLBM";

 /Compensation of employees: Wages and salaries
 /https://research.stlouisfed.org/fred2/series/A576RC1A027NBEA#
A576RC1A027NBEA:loadFed "A576RC1A027NBEA";

 /Average Hourly Earnings of Production and Nonsupervisory Employees: Total Private
 /https://research.stlouisfed.org/fred2/series/AHETPI
AHETPI:loadFed "AHETPI";

 /Employed full time: Median usual weekly real earnings: Wage and salary workers: 16 years and over
 /https://research.stlouisfed.org/fred2/series/LES1252881600Q
LES1252881600Q:loadFed "LES1252881600Q";

 /Federal Minimum Hourly Wage for Nonfarm Workers for the United States
 /https://research.stlouisfed.org/fred2/series/FEDMINNFRWG
FEDMINNFRWG:loadFed "FEDMINNFRWG"

QUANDLGLD:loadQuandlGold[]

divFed[GOLDAMGBD228NLBM; A576RC1A027NBEA] /wages and salaries
divFed[GOLDAMGBD228NLBM; AHETPI] /prod and non-superv
divFed[GOLDAMGBD228NLBM; LES1252881600Q] /full time
divFed[GOLDAMGBD228NLBM; FEDMINNFRWG] /min wage
divFed[GOLDAMGBD228NLBM; CPIFABSL] /food and bev
divFed[GOLDAMGBD228NLBM; CPIUFDNS] /food
divFed[GOLDAMGBD228NLBM; CUSR0000SAF112] /meat and eggs
divFed[GOLDAMGBD228NLBM; FEDFUNDS] /FEDFUNDS
divFed[GOLDAMGBD228NLBM; DGS10] /10y tres

divFed[CPIFABSL; A576RC1A027NBEA] /wages and salaries
divFed[CPIFABSL; AHETPI] /prod and non-superv
divFed[CPIFABSL; LES1252881600Q] /full time
divFed[CPIFABSL; FEDMINNFRWG] /min wage

divFed[A576RC1A027NBEA; AHETPI]
divFed[A576RC1A027NBEA; LES1252881600Q]
divFed[LES1252881600Q; AHETPI]
