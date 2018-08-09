function factorData = sFactor_T1_008(data,para)
% ===========换手率因子==================
% vol/oi
% 缺失数据做了时序上的补全
% -----------输入变量---------------
% data.Vol;data.Interest;data.Date-数据缺失值为nan，用比例后复权数据；原始的日期
% para.dateST;para.dateED-需要的日期
% -----------输出变量---------------
% factorData:col1-日期，面板数据
% inf的数据用0代替，品种不活跃造成的

dateBasic = data.Date;
fut_variety = data.fut_variety;
FPath = data.FPath;

dateST = para.dateST;
dateED = para.dateED;

% 面板数据
Vol = getBasicData(fut_variety,FPath,dateBasic,'Volume');
Interest = getBasicData(fut_variety,FPath,dateBasic,'Interest');

factorData = Vol./Interest;
factorData(isinf(factorData)) = 0; %如果持仓为0，用0代替inf，没有换手--品种极度不活跃
factorData = getFullTS(factorData); %时序上面补全数据
factorData = getNeedData(factorData,dateBasic,dateST,dateED); %从整个数据中截出需要的数据



    
    
