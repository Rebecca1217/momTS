% 因子回测
% 都是按照持有固定天数的方式来测的，没有加特定的平仓信号
% 两种回测模式：
% 1.按照多因子做法，多空配平
% 2.按照趋势做法，多空不配平
clear;
%% 参数设置
% 因子参数
PFactor.factorNum = '001';
PFactor.Type = 'TAlib\PR';
PFactor.FType = 'Ori';
PFactor.win = 0;
PFactor.HoldTime = 40; %持有期
PFactor.PassNum = PFactor.HoldTime; %通道数
PFactor.LongDirect = 'max'; %因子方向
PFactor.GroupNum = 5; %分组数
PFactor.TrendThr = [0,0];
% 整体参数
PGlobal.TestType = 'trend'; %回测方式：trend,hedge
%如果采用trend回测，则GroupNum用不到，并且会增加TrendThr来作为判断多空的阈值,TrendThr包括上下阈值，（2,1)矩阵
PGlobal.AllocateType = 'eqSize'; %配平方式：eqSize,eqATR
PGlobal.IndustryChoice = 'total'; %回测板块：total,
PGlobal.Position = 'flex'; %仓位调整房还是：full满仓,flex灵活变动
% 交易参数
cutLoss = []; %止损
cutProfit = []; %止盈
Cap.Capital = 10000000; %开仓市值
TradePara.fixC = 0.0002; %固定成本
TradePara.slip = 2; %滑点
TradePara.PType = 'avgP'; %交易价格
stDate = 20100101;
edDate = 20171031;
%% 路径设置
% 因子数据路径
PFactor.FactorPath = 'D:\期货数据2.0\因子测试数据\TALib\PR\Combine\001\Ori\1\win0';
% 交易数据路径
TradePara.futDataPath = 'D:\期货数据2.0\dlyDataCS\主力合约';
TradePara.futUnitPath = 'D:\期货数据2.0\usualData\minTickInfo.mat';
TradePara.futMultiPath = 'D:\期货数据2.0\usualData\PunitInfo';
TradePara.futLiquidPath = 'D:\期货数据2.0\usualData\liquidityInfo'; %流动性筛选
TradePara.futSectorPath = 'D:\期货数据2.0\usualData\SectorInfo.mat'; %板块筛选
TradePara.futMainContPath = 'D:\期货数据2.0\商品期货主力合约代码'; %主力合约代码
TradePara.usualPath = '..\data\usualData';%基础通用数据

% 调仓参数路径
if strcmpi(PGlobal.AllocateType,'eqATR') || ~isempty(cutLoss) || ~isempty(cutProfit)%ATR路径，因为止盈止损会用到ATR
    paraAlc.win = 14;
    paraAlc.budget = 100000; %风险预算
    paraAlc.ATRpath = ['..\data\usualData\ATRindex\win',num2str(paraAlc.win)]; %ATR数据存储路径
else
    paraAlc = [];
end
paraAlc.tdDPath = '..\data\adjData\主力合约'; %调仓通用路径-时序数据
paraAlc.usualPath = TradePara.usualPath; %基础通用数据
paraAlc.futLiquidPath = TradePara.futLiquidPath; %流动性筛选数据
paraAlc.futSectorPath = TradePara.futSectorPath; %板块筛选数据
paraAlc.IndustryChoice = PGlobal.IndustryChoice; %板块
% 信号函数路径
% addpath('gen_function')
addpath('usual_function')
addpath(genpath('..\newSystem3.0'))
% 生成日期
totalDate = getDate(stDate,edDate);
%% 回测
HandsDate = [totalDate;get_nextTraday(edDate)];
[HoldingInfo,HoldingInfoTM] = futAllocationFactor(PGlobal.AllocateType,Cap,paraAlc,HandsDate); % t日的开仓手数就记录在t行
for pn = 1:PFactor.PassNum
    factorDate = totalDate(pn:PFactor.HoldTime:end); %调仓日期的前一个交易日
    HoldingList = getHoldings(factorDate,PFactor,TradePara,PGlobal); %确定每期持仓
    % trend:HoldingList.TradeList-t日记录t+1日的持仓
    % hedge:HoldingList.TradeList,HoldingList.GroupList-t日记录t+1日的分组情况
    [HoldingPortfolio,HoldingPortfolioTM] = getHoldingHands(HoldingList,HoldingInfo,HoldingInfoTM,PGlobal,Cap,TradePara); %确定每期持仓品种的手数和权重
    % 将HoldingPortfolio的日期序列补齐，因为要求的输入是要连续的时间序列
    TargetPortfolio = get_ContiPortfolio(HoldingPortfolio.HoldingPortfolio,totalDate,TradePara.futMainContPath);
    [BacktestResult,err] = CTABacktest_GeneralPlatform(TargetPortfolio,TradePara);
    % 如果是hedge,还要考虑各组的持仓情况
    if strcmp(PGlobal.TestType,'hedge')
        for gn = 1:PFactor.GroupNum
            TradeList = getGroupList(HoldingList.GroupList,gn);
            GroupListGN = struct;
            GroupListGN.TradeList = TradeList;
            GroupHolding = getHoldingHands(GroupListGN,HoldingInfo,HoldingInfoTM,PGlobal,Cap,TradePara);
            GroupHolding = get_ContiPortfolio(GroupHolding.HoldingPortfolio,totalDate,TradePara.futMainContPath);
            str = ['Group.BTGroup',num2str(gn),' = CTABacktest_GeneralPlatform(GroupHolding,TradePara);'];
            eval(str)
            str = ['Group.AnaGroup',num2str(gn),' = CTAAnalysis_GeneralPlatform(Group.BTGroup',num2str(gn),');'];
            eval(str)
        end
        result.Group = Group;
    end
    % 绩效评价
    BacktestAnalysis = CTAAnalysis_GeneralPlatform(BacktestResult);
    % 存储
    result.BacktestResult = BacktestResult;
    result.BacktestAnalysis =  BacktestAnalysis;
    str = ['resultRecord.PassNum',num2str(pn),' = result;'];
    eval(str)
end

% 各个通道的结果汇总
rtn = [totalDate,zeros(length(totalDate),PFactor.PassNum)];
analysisPNSummary = cell(16,PFactor.PassNum+2);
nvPNSummary = [totalDate,zeros(length(totalDate),PFactor.PassNum+1)];
for pn = 1:PFactor.PassNum
    str = ['nvTmp = resultRecord.PassNum',num2str(pn),'.BacktestResult.nv;'];
    eval(str)
    [~,li0,li1] = intersect(totalDate,nvTmp(:,1));
    rtn(li0,pn+1) = nvTmp(li1,3);
    nvPNSummary(li0,pn+1) = nvTmp(li1,2);
    str = ['analysisPNSummary(:,pn+1) = resultRecord.PassNum',num2str(pn),'.BacktestAnalysis(:,2);'];
    eval(str)
end
nv = [totalDate,cumsum(mean(rtn(:,2:end),2)),mean(rtn(:,2:end),2)];
nv = nv(find(nv(:,3)~=0,1,'first'):end,:);
nvSummary = struct;
nvSummary.nv = nv;
analysisSummary = CTAAnalysis_GeneralPlatform(nvSummary);
analysisPNSummary(:,[1,end]) = analysisSummary;
[~,li0,li1] = intersect(totalDate,nv(:,1));
nvPNSummary(li0,end) = nv(li1,2);
nvPNSummary = nvPNSummary(find(nvPNSummary(:,end)~=0,1,'first'):end,:);
PNSummary.analysis = analysisPNSummary;
PNSummary.nv = nvPNSummary;
resultRecord.PNSummary = PNSummary;

    
    
    
    
    
    





