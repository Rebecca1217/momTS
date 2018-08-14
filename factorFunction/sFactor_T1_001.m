function factorData = sFactor_T1_001(data,para)
% ===========动量因子==================
% p(win+1)/p(1)-1
% 缺失数据做了时序上的补全
% -----------输入变量---------------
% data.fut_variety;data.FPath;data.Date-数据缺失值为nan，用比例后复权数据；原始的日期
% para.PType;para.win;para.dateST;para.dateED-需要的日期
% -----------输出变量---------------
% factorData:col1-日期，面板数据

dateBasic = data.Date;
fut_variety = data.fut_variety;
FPath = data.FPath;

PType = para.PType;
win = para.win;
dateST = para.dateST;
dateED = para.dateED;

% 面板数据
dataBasic = getBasicData(fut_variety,FPath,dateBasic,PType); %维度：时间+品种，变量只有Close一个

dataBasic_BF = [nan(win,size(dataBasic,2));dataBasic(1:end-win,:)];
factorData = dataBasic./dataBasic_BF-1;
factorData = getFullTS(factorData); %时序上面补全数据
factorData = getNeedData(factorData,dateBasic,dateST,dateED); %从整个数据中截出需要的数据



    
    
