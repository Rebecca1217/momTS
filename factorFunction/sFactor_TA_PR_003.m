function factorData = sFactor_TA_PR_003(data,para)
% ===========上吊线因子==================
% 缺失数据做了时序上的补全
% -----------输入变量---------------
% data.fut_variety;data.FPath;data.Date-数据缺失值为nan，用比例后复权数据；原始的日期
% para.dateST;para.dateED-需要的日期
% -----------输出变量---------------
% factorData:col1-日期，面板数据

dateBasic = data.Date;
fut_variety = data.fut_variety;
FPath = data.FPath;
winBF = 10;
winAF = 2;



dateST = para.dateST;
dateED = para.dateED;
FType = para.FType;
TypeOri = para.TypeOri;

% 面板数据
dataBasicO = getBasicData(fut_variety,FPath,dateBasic,'Open');
dataBasicC = getBasicData(fut_variety,FPath,dateBasic,'Close');
dataBasicH = getBasicData(fut_variety,FPath,dateBasic,'High');
dataBasicL = getBasicData(fut_variety,FPath,dateBasic,'Low');

flagYinYang = dataBasicC-dataBasicO; %判断阴线还是阳线
flagGaoDi = dataBasicH-dataBasicL; %最高价-最低价
maxP = zeros(size(dataBasicC)); %开收价中的高价
minP = zeros(size(dataBasicC)); %开收价中的低价
for l = 1:size(dataBasicC,2)
    maxP(:,l) = max([dataBasicC(:,l),dataBasicO(:,l)],[],2);
    minP(:,l) = min([dataBasicC(:,l),dataBasicO(:,l)],[],2);
end
flagUp = dataBasicH-maxP; %上引线的长度
flagDn = minP-dataBasicL; %下引线的长度
flagZD = [nan(winBF,size(dataBasicC,2));dataBasicC(winBF+1:end,:)-dataBasicC(1:end-winBF,:)]; %价格的涨跌
flagZD_AF = [nan(winAF,size(dataBasicC,2));dataBasicC(winAF+1:end,:)-dataBasicC(1:end-winAF,:)]; %价格的涨跌,形态出现之后

% K线形态
if strcmp(TypeOri,'Ori')
    % 阳线、上引线很短且长度小于实体的长度、实体小
    LenUp = flagUp./flagGaoDi<0.2 & flagUp<abs(flagYinYang); %上引线长度
    LenShi = abs(flagYinYang)./flagGaoDi<0.25; %实体小
    flagKbar = flagYinYang>0 & LenUp & LenShi;
elseif strcmp(TypeOri,'ChgO1_1')
    % 上引线很短且长度小于实体的长度、实体小
    LenUp = flagUp./flagGaoDi<0.2 & flagUp<abs(flagYinYang); %上引线长度
    LenShi = abs(flagYinYang)./flagGaoDi<0.25; %实体小
    flagKbar = LenUp & LenShi;
elseif strcmp(TypeOri,'Ori2')
    % 阴线、下引线很短且长度小于实体的长度、实体小
    LenDn = flagDn./flagGaoDi<0.2 & flagDn<abs(flagYinYang); %上引线长度
    LenShi = abs(flagYinYang)./flagGaoDi<0.25; %实体小
    flagKbar = flagYinYang<0 & LenDn & LenShi;
elseif strcmp(TypeOri,'ChgO2_1')
    % 下引线很短且长度小于实体的长度、实体小
    LenDn = flagDn./flagGaoDi<0.2 & flagDn<abs(flagYinYang); %上引线长度
    LenShi = abs(flagYinYang)./flagGaoDi<0.25; %实体小
    flagKbar = LenDn & LenShi;
end
   
  
factorData = zeros(size(dataBasicO)); %开多1，开空-1，其余为0

if FType==1 %单独考虑k线形态
    flagL = flagKbar;
    factorData(flagL==1) = 1;
elseif FType==2 %K线形态+前期的趋势
    flagS = flagZD>0 & flagKbar; %前期上涨且出现该形态
    flagL = flagZD<0 & flagKbar; %前期下跌且出现该形态
    factorData(flagL==1) = 1;
    factorData(flagS==1) = -1;
elseif FType==3 %K线形态+前期的趋势+后期的趋势
    flagL1 = flagZD<0 & flagKbar; %前期下跌且出现该形态
    flagS1 = flagZD>0 & flagKbar; %前期上涨且出现该形态
    flagS1_shift = [nan(winAF+1,size(flagS1,2));flagS1(1:end-winAF-1,:)];
    flagL1_shift = [nan(winAF+1,size(flagL1,2));flagL1(1:end-winAF-1,:)];
    flagS = flagS1_shift==1 & flagZD_AF<0; %前期上涨且出现该形态,且后期下跌
    flagL = flagL1_shift==1 & flagZD_AF>0; %前期下跌且出现该形态,且后期上涨
    factorData(flagL==1) = 1;
    factorData(flagS==1) = -1;
end

    
factorData = getNeedData(factorData,dateBasic,dateST,dateED); %从整个数据中截出需要的数据



    
    
