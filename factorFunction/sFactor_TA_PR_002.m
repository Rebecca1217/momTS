function factorData = sFactor_TA_PR_002(data,para)
% ===========阴阳阳和阳阴阴因子==================
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
FType = para.FType;

% 面板数据
dataBasicO = getBasicData(fut_variety,FPath,dateBasic,'Open');
dataBasicC = getBasicData(fut_variety,FPath,dateBasic,'Close');
dataBasicH = getBasicData(fut_variety,FPath,dateBasic,'High');
dataBasicL = getBasicData(fut_variety,FPath,dateBasic,'Low');

flagYinYang = dataBasicC-dataBasicO; %判断阴线还是阳线
flagDifH = [nan(1,size(dataBasicH,2));diff(dataBasicH)]; %最高价的差值
flagDifL = [nan(1,size(dataBasicL,2));diff(dataBasicL)]; %最低价的差值

factorData = zeros(size(dataBasicO)); %开多1，开空-1，其余为0
for t = 3:length(dateBasic)
    if FType==1
        % 多
        CL1 = flagYinYang(t-2,:)<0 & flagYinYang(t-1,:)>0 & flagYinYang(t,:)>0; %阴阳阳
        CL2 = flagDifL(t,:)>0 & dataBasicO(t-2,:)-dataBasicC(t,:)<0; %
        CL3 = (flagDifH(t-1,:)>=0 & flagDifL(t-1,:)<=0) | (flagDifH(t-1,:)<=0 & flagDifL(t-1,:)>=0); %Kbar(lag1)和Kbar(lag2)为吞没形态
        % 空
        CS1 = flagYinYang(t-2,:)>0 & flagYinYang(t-1,:)<0 & flagYinYang(t,:)<0; %阳阴阴
        CS2 = flagDifH(t,:)<0 & dataBasicO(t-2,:)-dataBasicC(t,:)>0;
        CS3 = dataBasicO(t-1,:)-dataBasicO(t-2,:)>0 & dataBasicO(t,:)-dataBasicC(t-1,:)>0; %高开
        %
        flagS = CS1 & CS2 & CS3;
        flagL = CL1 & CL2 & CL3;
        factorData(t,flagL==1) = 1;
        factorData(t,flagS==1) = -1;
    else
        % 多
        CL1 = flagYinYang(t-2,:)<0 & flagYinYang(t-1,:)>0 & flagYinYang(t,:)>0; %阴阳阳
        CL2 = flagDifH(t,:)>0 & dataBasicC(t-1,:)-dataBasicL(t-2,:)>0;
        % 空
        CS1 = flagYinYang(t-2,:)>0 & flagYinYang(t-1,:)>0 & flagYinYang(t,:)<0; %阳阳阴
        CS2 = flagDifL(t,:)<0 & dataBasicC(t-1,:)-dataBasicH(t-2,:)>0;
             %
        flagS = CS1 & CS2;
        flagL = CL1 & CL2;
        factorData(t,flagL==1) = 1;
        factorData(t,flagS==1) = -1;
    end
end
    
factorData = getNeedData(factorData,dateBasic,dateST,dateED); %从整个数据中截出需要的数据



    
    
