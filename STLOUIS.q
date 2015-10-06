\cd /home/alex/kdb/data
\cd 

 loadY:{[sym]
 t:.z.d;
 y:string t.year;
 m:string t.mm-1;
 d:string t.dd;
 system "rm table.csv"
 system "curl -o table.csv http://real-chart.finance.yahoo.com/table.csv?s=",sym,"&d=",m,"&e=",d,"&f=",y,"&g=d&a=1&b=1&c=1000&ignore=.csv";
 T:("DFFFFIF"; enlist ",") 0:`table.csv;
 T:`Date`Open`High`Low`Close`Volume`AdjClose xcol T;
 `DATE xkey select DATE:Date, VALUE:AdjClose from T
 };

reverse loadY "MSFT"

loadFed:{[sym]
 system "cd /home/alex/kdb/data";
 system "curl -o ",sym,".csv https://research.stlouisfed.org/fred2/series/",sym,"/downloaddata/",sym,".csv";
 `DATE xkey ("DF"; enlist ",") 0:`$sym,".csv"
 };

loadQuandlGold:{[]
 system "curl -o quandl-gold.csv https://www.quandl.com/api/v3/datasets/BUNDESBANK/BBK01_WT5511.csv";
 `DATE xkey (select DATE:Date, VALUE:Value from ("DF"; enlist ",") 0:`$"quandl-gold.csv")
 };

loadQuandlUsdJpy:{[]
 system "curl -o quandl-gold.csv https://www.quandl.com/api/v3/datasets/CURRFX/USDJPY.csv";
 `DATE xkey (select DATE:Date, VALUE:Rate from ("DF"; enlist ",") 0:`$"quandl-gold.csv")
 };

avgByYear:{[tbl] select VALUE:avg[VALUE] by YEAR:DATE.year from tbl};

pair:{
 select YEAR, nom%den from 
 (`YEAR xkey select YEAR, nom:VALUE from avgByYear[x]) ij 
 (`YEAR xkey select YEAR, den:VALUE from avgByYear[y])
 };

pairNoAggr:{
 select DATE, nom%den from 
 (`DATE xkey select DATE, nom:VALUE from x) ij 
 (`DATE xkey select DATE, den:VALUE from y)
 };

 /https://research.stlouisfed.org/fred2/tags/series?t=wages
M2:loadFed "M2";
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

pair[GOLDAMGBD228NLBM; A576RC1A027NBEA] /wages and salaries
pair[GOLDAMGBD228NLBM; AHETPI] /prod and non-superv
pair[GOLDAMGBD228NLBM; LES1252881600Q] /full time
pair[GOLDAMGBD228NLBM; FEDMINNFRWG] /min wage
pair[GOLDAMGBD228NLBM; CPIFABSL] /food and bev
pair[GOLDAMGBD228NLBM; CPIUFDNS] /food
pair[GOLDAMGBD228NLBM; CUSR0000SAF112] /meat and eggs
pair[GOLDAMGBD228NLBM; FEDFUNDS] /FEDFUNDS
pair[GOLDAMGBD228NLBM; DGS10] /10y tres
pair[GOLDAMGBD228NLBM; M2] /M2

pair[CPIFABSL; A576RC1A027NBEA] /wages and salaries
pair[CPIFABSL; AHETPI] /prod and non-superv
pair[CPIFABSL; LES1252881600Q] /full time
pair[CPIFABSL; FEDMINNFRWG] /min wage

pair[A576RC1A027NBEA; AHETPI]
pair[A576RC1A027NBEA; LES1252881600Q]
pair[LES1252881600Q; AHETPI]

SPY:loadY "SPY"
JPY:loadQuandlUsdJpy[]

reverse pairNoAggr[SPY;JPY]
reverse select from (`DATE xkey select DATE, spy:VALUE from SPY) ij (`DATE xkey select DATE, jpy:VALUE from JPY)
