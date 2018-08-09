function factorData = sFactor_T1_003(data,para)
% ==================开盘跳价因子================
% O(t)/C(t-1)-1
% --------------输入变量-------------------
% data.fut_variety;data.FPath;data.Date;
% para.dateST;para.dateED
% --------------输出变量------------------
% factorData:col1-日期，面板数据


dateBasic = data.Date;
fut_variety = data.fut_variety;
FPath = data.FPath;

dateST = para.dateST;
dateED = para.dateED;

% 面板数据
Open = getBasicData(fut_variety,FPath,dateBasic,'Open');
Close = getBasicData(fut_variety,FPath,dateBasic,'Close');

Close_BF = [nan(1,size(Close,2));Close(1:end-1,:)];

factorData = Open./Close_BF-1;
factorData = getFullTS(factorData); %时序上面补全数据
factorData = getNeedData(factorData,dateBasic,dateST,dateED); %从整个数据中截出需要的数据