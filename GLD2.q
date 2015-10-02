/
a mikey mouse backtesting of straddle strategy for GLD;
shows that market is efficient and one cannot squeeze 
a positive PL from it;
\

\cd /home/alex/kdb/data
/load GLD data
system "curl -o table.csv http://real-chart.finance.yahoo.com/table.csv?s=GLD&d=8&e=22&f=2015&g=d&a=10&b=18&c=2004&ignore=.csv";
T:("DFFFFIF"; enlist ",") 0:`table.csv;
 
 /generate simple PL report;
 /takes: array of prices; strike; trade fee
 /counts: how many trades gained (expired below strike),
 /how many trades lost (were assigned above the strike),
 /calculates losses (sum p-k) and gains (using global 'opt' dict
 /containing strike->price pairs)
report:{[p; k; fee] 
 diff:p-k;
 /diff>0: loss (price went above the strike); diff<0: gain (option expired)
 losses:sum diff*(diff>0);
 gains:sum opt[kdn]*(diff<0);
 fees:(count diff)*fee;
 "losses:", string[losses],
 "\ngains:",string[gains],
 "\nfees:",string[fees],
 "\ntimes lost:",string[sum (diff>0)],
 "\ntime gained:",string[sum (diff<0)],
 "\nPL:",string[gains-(losses+fees)]
 };

 /takes set of rows (date;value)
 /takes date of the first row and calculates
 /min/max/range etc stats on values;
 /returns dictionary
sliceStat:{[r]
 /grab date from the first row
 d:(first r)[0];
 /take values from second column from all rows
 v:r[;1];
 /run some stats on values and add them to a dict
 `dt`op`mx`mn`rg`up`dn!
 (d; first v;max v;min v;max v - min v;max v - first v;first v - min v)
 };

 /takes last N days from table of prices,
 /slices the table with sliding window,
 /calculates stats for each slice and puts all stats in a table
allStats:{[table;wnd;days]
 table:days # table;
 table:reverse table;
 /read close prices
 close:flip table[`Date`Close];
 rows:count close;
 /beg indexes of each slice
 i1:(neg wnd) _ til rows;
 /end indexex of each slice
 i2:wnd _ til rows;
 /pair indexes in a table (ranges)
 rngs:(flip (i1;i2));
 /func that takes a slice of rows based on beg;end indexes (range)
 /ii:(beg idx; end idx)
 slice:{[a; ii] ii[0] _ (ii[1] # a)};
 /project 'slice': bind first param to list of (date;price)
 /then use projection to go over each range and create slices
 closeSlices:slice[close;] each rngs;
 /calc stats for each slice
 statSlices:sliceStat each closeSlices
 };

run:{[table;wnd;days;kup;kdn; fee; opt] 
 statSlices:allStats[table;wnd;days];
 ups:statSlices`up;
 dns:statSlices`dn;
 rup:report[ups; kup; fee];
 rdn:report[dns; kdn; fee];
 0N! "---CALLS\n",rup,"\n---PUTS\n",rdn
 };

 /8 days until expiration
opt:(1.5, 2.0, 2.5, 3.0, 3.5, 4.0)!(0.4, 0.3, 0.25, 0.2, 0.16, 0.1);
run[T; 8; 365; 4.0; 3.5; 0.1; opt]
 /30 days until expiration
opt:(.5, 1., 1.5, 2., 2.5, 3., 3.5, 4., 4.5, 5, 5.5, 6)!
 (1.6, 1.4, 1.3, 1.1, .9, .7, .6, .5, .47, .42, .35, .3);
run[T; 30; 165; 5.; 5.; .01; opt]
