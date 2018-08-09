% 因子回测2.0
% 都是按照持有固定天数的方式来测的，没有加特定的平仓信号
% 两种回测模式：
% 1.按照多因子做法，多空配平
% 2.按照趋势做法，多空不配平
% -----------------------20180329修改内容-------------------------
% 1.将之前截面回测的方式改成了按照品种回测的方式
clear;
%% 参数设置
% 因子参数
PFactor.factorNum = '001'; %因子编号
PFactor.Type = 'TAlib\PR'; %因子类别
PFactor.FType = 'Ori'; %因子变形类型
PFactor.win = 0; %因子窗口期参数
PFactor.HoldTime = 40; %持有期
PFactor.PassNum = PFactor.HoldTime; %通道数
PFactor.LongDirect = 'max'; %因子方向，max:做多排名靠前的一组，min:做多排名靠后的一组
PFactor.GroupNum = 5; %分组数，一般2、3、5
PFactor.TrendThr = [0,0]; %判断趋势的阈值
% 整体参数
PGlobal.TestType = 'trend'; %回测方式：trend（多空不配平）,hedge（多空配平）
%如果采用trend回测，则GroupNum用不到，并且会增加TrendThr来作为判断多空的阈值,TrendThr包括上下阈值，（2,1)矩阵
PGlobal.AllocateType = 'eqSize'; %配平方式：eqSize（等市值）,eqATR（等ATR)
PGlobal.IndustryChoice = 'total'; %回测板块：total(全样本）
PGlobal.Position = 'flex'; %仓位调整房还是：full满仓,flex灵活变动
% 交易参数
cutLoss = []; %止损，先不考虑
cutProfit = []; %止盈，先不考虑
Cap.Capital = 10000000; %开仓市值
TradePara.fixC = 0.0002; %固定成本
TradePara.slip = 2; %滑点
TradePara.PType = 'avg'; %交易价格，一般用open（开盘价）或者avg(日均价）
stDate = 20100101; %回测开始日期
edDate = 20171031; %回测结束日期
%% 路径设置
% 因子数据路径
PFactor.FactorPath = '\\Cj-lmxue-dt\期货数据2.0\因子测试数据\TALib\PR\Combine\001\Ori\1\win0'; %因子数据存储路径
% 交易数据路径
TradePara.futDataPath = 'D:\期货数据2.0\dlyData\主力合约'; %期货主力合约数据路径
TradePara.futUnitPath = 'D:\期货数据2.0\usualData\minTickInfo.mat'; %期货最小变动单位
TradePara.futMultiPath = 'D:\期货数据2.0\usualData\PunitInfo'; %期货合约乘数
TradePara.futLiquidPath = 'D:\期货数据2.0\usualData\liquidityInfo'; %期货品种流动性数据，用来筛选出活跃品种，剔除不活跃品种
TradePara.futSectorPath = 'D:\期货数据2.0\usualData\SectorInfo.mat'; %期货样本池数据，用来确定样本集对应的品种
TradePara.futMainContPath = 'D:\期货数据2.0\商品期货主力合约代码'; %主力合约代码
TradePara.usualPath = '..\data\usualData';%基础通用数据

% 调仓参数路径
if strcmpi(PGlobal.AllocateType,'eqATR') || ~isempty(cutLoss) || ~isempty(cutProfit)%ATR路径，因为止盈止损会用到ATR
    paraAlc.win = 14; %ATR计算的窗口期参数，14或20
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
addpath(genpath('newSystem3.0')) %回测函数
% 生成日期
totalDate = getDate(stDate,edDate);
%% 回测
HandsDate = [totalDate;get_nextTraday(edDate)];
[HoldingInfo,HoldingInfoTM] = futAllocationFactor(PGlobal.AllocateType,Cap,paraAlc,HandsDate); % 生成每日持仓手数，t日的开仓手数就记录在t行
for pn = 1:PFactor.PassNum
    factorDate = totalDate(pn:PFactor.HoldTime:end); %调仓日期的前一个交易日
    HoldingList = getHoldings(factorDate,PFactor,TradePara,PGlobal); %确定每期持仓
    % trend:HoldingList.TradeList-t日记录t+1日的持仓
    % hedge:HoldingList.TradeList,HoldingList.GroupList-t日记录t+1日的分组情况
    [HoldingPortfolio,HoldingPortfolioTM] = getHoldingHands(HoldingList,HoldingInfo,HoldingInfoTM,PGlobal,Cap,TradePara); %确定每期持仓品种的手数和权重
    % 将HoldingPortfolio的日期序列补齐，因为要求的输入是要连续的时间序列
    TargetPortfolio = get_ContiPortfolio(HoldingPortfolio.HoldingPortfolio,totalDate,TradePara.futMainContPath);
    [BacktestResult,err] = CTABacktest_GeneralPlatform_3(TargetPortfolio,TradePara);
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
    BacktestAnalysis = CTAAnalysis_GeneralPlatform_2(BacktestResult);
    % 存储
    result.BacktestResult = BacktestResult;
    result.BacktestAnalysis =  BacktestAnalysis;
    str = ['resultRecord.PassNum',num2str(pn),' = result;'];
    eval(str)
end

% 各个通道的结果汇总
rtn = [totalDate,zeros(length(totalDate),PFactor.PassNum)];
analysisPNSummary = cell(13,PFactor.PassNum+2);
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

% 测试结果记录在resultRecord中，存储resultRecord

    
    
    
    
    
    





