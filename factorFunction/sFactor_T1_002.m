function factorData = sFactor_T1_002(data,para)
% =============价格相对位置因子==================
% (C-LL)/(HH-LL)
% HH=max(H[1:win])
% --------------输入变量-------------------
% data.fut_variety;data.FPath;data.Date
% para.win;para.dateST;para.dateED
% --------------输出变量------------------
% factorData:col1-日期，面板数据

dateBasic = data.Date;
fut_variety = data.fut_variety;
FPath = data.FPath;

win = para.win;
dateST = para.dateST;
dateED = para.dateED;

% 面板数据
High = getBasicData(fut_variety,FPath,dateBasic,'High');
Low = getBasicData(fut_variety,FPath,dateBasic,'Low');
Close = getBasicData(fut_variety,FPath,dateBasic,'Close');


HH = hhigh(High,win,1);
HH(1:win-1,:) = nan;
LL = llow(Low,win,1);
LL(1:win-1,:) = nan;

factorData = (Close-LL)./(HH-LL);
factorData = getFullTS(factorData); %时序上面补全数据
factorData = getNeedData(factorData,dateBasic,dateST,dateED); %从整个数据中截出需要的数据
