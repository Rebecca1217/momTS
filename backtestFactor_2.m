% ���ӻز�2.0
% ���ǰ��ճ��й̶������ķ�ʽ����ģ�û�м��ض���ƽ���ź�
% ���ֻز�ģʽ��
% 1.���ն����������������ƽ
% 2.����������������ղ���ƽ
% -----------------------20180329�޸�����-------------------------
% 1.��֮ǰ����ز�ķ�ʽ�ĳ��˰���Ʒ�ֻز�ķ�ʽ
clear;
%% ��������
% ���Ӳ���
PFactor.factorNum = '001'; %���ӱ��
PFactor.Type = 'TAlib\PR'; %�������
PFactor.FType = 'Ori'; %���ӱ�������
PFactor.win = 0; %���Ӵ����ڲ���
PFactor.HoldTime = 40; %������
PFactor.PassNum = PFactor.HoldTime; %ͨ����
PFactor.LongDirect = 'max'; %���ӷ���max:����������ǰ��һ�飬min:�������������һ��
PFactor.GroupNum = 5; %��������һ��2��3��5
PFactor.TrendThr = [0,0]; %�ж����Ƶ���ֵ
% �������
PGlobal.TestType = 'trend'; %�زⷽʽ��trend����ղ���ƽ��,hedge�������ƽ��
%�������trend�ز⣬��GroupNum�ò��������һ�����TrendThr����Ϊ�ж϶�յ���ֵ,TrendThr����������ֵ����2,1)����
PGlobal.AllocateType = 'eqSize'; %��ƽ��ʽ��eqSize������ֵ��,eqATR����ATR)
PGlobal.IndustryChoice = 'total'; %�ز��飺total(ȫ������
PGlobal.Position = 'flex'; %��λ���������ǣ�full����,flex���䶯
% ���ײ���
cutLoss = []; %ֹ���Ȳ�����
cutProfit = []; %ֹӯ���Ȳ�����
Cap.Capital = 10000000; %������ֵ
TradePara.fixC = 0.0002; %�̶��ɱ�
TradePara.slip = 2; %����
TradePara.PType = 'avg'; %���׼۸�һ����open�����̼ۣ�����avg(�վ��ۣ�
stDate = 20100101; %�ز⿪ʼ����
edDate = 20171031; %�ز��������
%% ·������
% ��������·��
PFactor.FactorPath = '\\Cj-lmxue-dt\�ڻ�����2.0\���Ӳ�������\TALib\PR\Combine\001\Ori\1\win0'; %�������ݴ洢·��
% ��������·��
TradePara.futDataPath = 'D:\�ڻ�����2.0\dlyData\������Լ'; %�ڻ�������Լ����·��
TradePara.futUnitPath = 'D:\�ڻ�����2.0\usualData\minTickInfo.mat'; %�ڻ���С�䶯��λ
TradePara.futMultiPath = 'D:\�ڻ�����2.0\usualData\PunitInfo'; %�ڻ���Լ����
TradePara.futLiquidPath = 'D:\�ڻ�����2.0\usualData\liquidityInfo'; %�ڻ�Ʒ�����������ݣ�����ɸѡ����ԾƷ�֣��޳�����ԾƷ��
TradePara.futSectorPath = 'D:\�ڻ�����2.0\usualData\SectorInfo.mat'; %�ڻ����������ݣ�����ȷ����������Ӧ��Ʒ��
TradePara.futMainContPath = 'D:\�ڻ�����2.0\��Ʒ�ڻ�������Լ����'; %������Լ����
TradePara.usualPath = '..\data\usualData';%����ͨ������

% ���ֲ���·��
if strcmpi(PGlobal.AllocateType,'eqATR') || ~isempty(cutLoss) || ~isempty(cutProfit)%ATR·������Ϊֹӯֹ����õ�ATR
    paraAlc.win = 14; %ATR����Ĵ����ڲ�����14��20
    paraAlc.budget = 100000; %����Ԥ��
    paraAlc.ATRpath = ['..\data\usualData\ATRindex\win',num2str(paraAlc.win)]; %ATR���ݴ洢·��
else
    paraAlc = [];
end
paraAlc.tdDPath = '..\data\adjData\������Լ'; %����ͨ��·��-ʱ������
paraAlc.usualPath = TradePara.usualPath; %����ͨ������
paraAlc.futLiquidPath = TradePara.futLiquidPath; %������ɸѡ����
paraAlc.futSectorPath = TradePara.futSectorPath; %���ɸѡ����
paraAlc.IndustryChoice = PGlobal.IndustryChoice; %���
% �źź���·��
% addpath('gen_function')
addpath('usual_function')
addpath(genpath('newSystem3.0')) %�ز⺯��
% ��������
totalDate = getDate(stDate,edDate);
%% �ز�
HandsDate = [totalDate;get_nextTraday(edDate)];
[HoldingInfo,HoldingInfoTM] = futAllocationFactor(PGlobal.AllocateType,Cap,paraAlc,HandsDate); % ����ÿ�ճֲ�������t�յĿ��������ͼ�¼��t��
for pn = 1:PFactor.PassNum
    factorDate = totalDate(pn:PFactor.HoldTime:end); %�������ڵ�ǰһ��������
    HoldingList = getHoldings(factorDate,PFactor,TradePara,PGlobal); %ȷ��ÿ�ڳֲ�
    % trend:HoldingList.TradeList-t�ռ�¼t+1�յĳֲ�
    % hedge:HoldingList.TradeList,HoldingList.GroupList-t�ռ�¼t+1�յķ������
    [HoldingPortfolio,HoldingPortfolioTM] = getHoldingHands(HoldingList,HoldingInfo,HoldingInfoTM,PGlobal,Cap,TradePara); %ȷ��ÿ�ڳֲ�Ʒ�ֵ�������Ȩ��
    % ��HoldingPortfolio���������в��룬��ΪҪ���������Ҫ������ʱ������
    TargetPortfolio = get_ContiPortfolio(HoldingPortfolio.HoldingPortfolio,totalDate,TradePara.futMainContPath);
    [BacktestResult,err] = CTABacktest_GeneralPlatform_3(TargetPortfolio,TradePara);
    % �����hedge,��Ҫ���Ǹ���ĳֲ����
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
    % ��Ч����
    BacktestAnalysis = CTAAnalysis_GeneralPlatform_2(BacktestResult);
    % �洢
    result.BacktestResult = BacktestResult;
    result.BacktestAnalysis =  BacktestAnalysis;
    str = ['resultRecord.PassNum',num2str(pn),' = result;'];
    eval(str)
end

% ����ͨ���Ľ������
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

% ���Խ����¼��resultRecord�У��洢resultRecord

    
    
    
    
    
    





