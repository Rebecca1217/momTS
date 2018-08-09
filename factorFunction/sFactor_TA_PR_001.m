function factorData = sFactor_TA_PR_001(data,para)
% ===========三连阴三连阳因子==================
% 缺失数据做了时序上的补全
% -----------输入变量---------------
% data.fut_variety;data.FPath;data.Date-数据缺失值为nan，用比例后复权数据；原始的日期
% para.dateST;para.dateED-需要的日期
% -----------输出变量---------------
% factorData:col1-日期，面板数据

dateBasic = data.Date;
fut_variety = data.fut_variety;
FPath = data.FPath;

dateST = para.dateST;
dateED = para.dateED;

% 面板数据
dataBasicO = getBasicData(fut_variety,FPath,dateBasic,'Open');
dataBasicC = getBasicData(fut_variety,FPath,dateBasic,'Close');
dataBasicH = getBasicData(fut_variety,FPath,dateBasic,'High');
dataBasicL = getBasicData(fut_variety,FPath,dateBasic,'Low');

flagYinYang = dataBasicC-dataBasicO; %判断阴线还是阳线
flagDifC = [nan(1,size(dataBasicC,2));diff(dataBasicC)]; %收盘价的差值
flagGap = [nan(1,size(dataBasicC,2));dataBasicO(2:end,:)-dataBasicC(1:end-1,:)]; %开盘跳空

factorData = zeros(size(dataBasicO)); %开多1，开空-1，其余为0
for t = 3:length(dateBasic)
    % 三连阴
    Yin3 = flagYinYang(t,:)<0 & flagYinYang(t-1,:)<0 & flagYinYang(t-2,:)<0;
%     Yin3 = (flagYinYang(t,:)<0) + (flagYinYang(t-1,:)<0) + (flagYinYang(t-2,:)<0)>=2;
    DifCDn = flagDifC(t,:)<0 & flagDifC(t-1,:)<0;
    GapDn = flagGap(t,:)>=0 | flagGap(t-1,:)>=0; %不能连续两次向下跳空开盘
    % 三连阳
    Yang3 = flagYinYang(t,:)>0 & flagYinYang(t-1,:)>0 & flagYinYang(t-2,:)>0;
%     Yang3 = (flagYinYang(t,:)>0) + (flagYinYang(t-1,:)>0) + (flagYinYang(t-2,:)>0)>=2;
    DifCUp = flagDifC(t,:)>0 & flagDifC(t-1,:)>0;
    GapUp = flagGap(t,:)<=0 |flagGap(t-1,:)<=0; %不能连续两次向上跳空开盘
    
    %
    flagS = Yin3 & DifCDn ;%& GapDn;
    flagL = Yang3 & DifCUp ;%;& GapUp;
    factorData(t,flagL==1) = 1;
    factorData(t,flagS==1) = -1;
end
    
factorData = getNeedData(factorData,dateBasic,dateST,dateED); %从整个数据中截出需要的数据



    
    
