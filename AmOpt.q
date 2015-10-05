 /https://thesweeheng.wordpress.com/category/kq/
 /binomial price tree
 /n: num steps; S: stock price; u: scale of the up move
 BPTree:{[n;S;u] n {(x*(1#y)),y%x}[u] \ enlist S};  
 
 /R is a reduction function, 
 /P is the payoff function, 
 /S is the current price, 
 /T is the time to maturity, 
 /r is the risk-free rate, 
 /b is the cost of carry, 
 /v is the volatility and 
 /n is the depth of the tree
GBM:{[R;P;S;T;r;b;v;n]                  / General Binomial Model (CRR)
 t:T%n;                                 / time interval
 u:exp v*sqrt t;                        / up; down is 1/u
 p:(exp[b*t]-1%u)%(u-1%u);              / probability of up
 ptree:reverse BPTree[n;S;u];           / reverse binomial price tree
 first R[exp[neg r*t];p] over P ptree};

 /reduction function
American:{[D;p;a;b] max(b;D*(-1_a*p)+1_a*1-p)};
European:{[D;p;a;b] D*(-1_a*p)+1_a*1-p};

ABM:GBM[American];
EBM:GBM[European];

 /payoff function
VP:{[S;K]max(K-S;0)};

ABM[VP[;106];108.99;29%356;0.0019;0.0;0.1433;30]
EBM[VP[;106];108.99;29%356;0.0019;0.0;0.1433;30]
