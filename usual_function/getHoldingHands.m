function [Portfolio,PortfolioTM] = getHoldingHands(HoldingList,HoldingInfo,HoldingInfoTM,PGlobal,Cap,PPath)
% 得到各个品种的持仓权重和手数
% 注意：HoldingList的日期和HoldingInfo的日期不是对齐的
% HoldingList里面t日记录t+1的持仓品种和方向
% HoldingInfo里面t日记录t的持仓手数,HoldingInfo里面的日期序列要比HoldingList里面的多一天
% 首先要将HoldingInfo的记录方式调整成和HoldingList一样

% 参数
% TestType = PGlobal.TestType;
position = PGlobal.Position; %仓位配置方式
Capital = Cap.Capital;
futDataPath = PPath.futDataPath;
usualPath = PPath.usualPath;
futMainContPath = PPath.futMainContPath;
% HoldingInfo调整
fut_variety = HoldingInfo.fut_variety;
HandsInfo = [HoldingInfo.Hands;HoldingInfoTM.Hands]; %手数配置
WeightInfo = [HoldingInfo.NomWeight;HoldingInfoTM.NomWeight]; %权重配置
infoDate = HandsInfo(:,1); %HoldingInfo对应的日期
%
TradeList = HoldingList.TradeList;
% 20180315修改部分
empL = cell2mat(cellfun(@(x) isempty(x),TradeList(:,1),'UniformOutput',0));
TradeList(empL,:) = [];
tradeDate = cell2mat(TradeList(:,2)); %TradeList对应的日期
% 日期记录方式对齐，infoDate要取t+1日的持仓手数，才是tradeList对应的t日的配置手数
[~,~,li1] = intersect(tradeDate,infoDate);
HandsInfo = [tradeDate,HandsInfo(li1+1,2:end)];
WeightInfo = [tradeDate,WeightInfo(li1+1,2:end)];

% 计算手数
HoldingPortfolio = cell(length(tradeDate),2);
HoldingPortfolio(:,2) = num2cell(tradeDate);
HoldingWeight = cell(length(tradeDate),2);
HoldingWeight(:,2) = num2cell(tradeDate);
if strcmp(position,'flex') %仓位灵活配置-仅对trend使用
    % 不用对手数进行调整，找到对应的手数就可以了
    for d = 1:length(tradeDate)
        tradeInfoI = TradeList{d,1}; %d+1日的持仓品种和方向
        if isempty(tradeInfoI)
            continue;
        end
        HandsInfoI = HandsInfo(d,2:end); %d+1日各品种对应的手数
        [futI,li0,li1] = intersect(tradeInfoI(:,1),fut_variety);
        handsWithDirect = cell2mat(tradeInfoI(li0,2)).*HandsInfoI(li1)'; %方向乘以手数
        portfolioI = [futI,num2cell(handsWithDirect)];
        WeightInfoI = WeightInfo(d,2:end);
        WeightI = [futI,num2cell(WeightInfoI(li1)')];
        %
        HoldingPortfolio{d,1} = portfolioI;
        HoldingWeight{d,1} = WeightI;
    end
    elseif strcmp(position,'full') %满仓化处理
    % 需要根据持仓权重占比对手数进行调整
    % 导入合约乘数
    load([usualPath,'\cont_multi.mat'])
    for d = 1:length(tradeDate)
        tradeInfoI = TradeList{d,1};
        if isempty(tradeInfoI)
            continue;
        end
        WeightInfoI = WeightInfo(d,2:end); %持仓占比
        [futI,li0,li1] = intersect(tradeInfoI(:,1),fut_variety);
        WeightInfoI = WeightInfoI(li1); %持有的品种的持仓权重
        WeightInfoI = WeightInfoI./sum(WeightInfoI); %权重再分配
        SizeI = Capital*WeightInfoI; %每个品种的开仓市值
        % 导入当日的截面数据
        load([futDataPath,'\',num2str(tradeDate(d)),'.mat'])
        ClCS = futureDataCS.Close; %收盘价
        futCS = futureDataCS.futName; %品种
        futCS = regexp(futCS,'\D*(?=\d)','match');
        futCS = reshape([futCS{:}],size(futCS));
        [~,~,li2] = intersect(futI,futCS,'stable');
        mainDataI = ClCS(li2);
        [~,~,li2] = intersect(futI,cont_multi(:,1),'stable'); %顺序问题
        contMulti = cont_multi(li2,:);
        contMulti = cell2mat(contMulti(:,2));
        HandsI = round(SizeI'./(mainDataI.*contMulti));
        %
        PortfolioI = cell2mat(tradeInfoI(li0,2)).*HandsI;
        HoldingPortfolio{d,1} = [futI,num2cell(PortfolioI)];
        HoldingWeight{d,1} = [futI,num2cell(HandsI.*mainDataI.*contMulti/Capital)];
    end
        
end


PortfolioTM.HoldingPortfolio = HoldingPortfolio(end,:);
PortfolioTM.HoldingWeight = HoldingWeight(end,:);
if tradeDate(end) == infoDate(end-1) %最后一个调仓日是明天，还没到
    HoldingPortfolio(end,:) = [];
    HoldingWeight(end,:) = [];
end
% 从首个有持仓的日期开始
stL = cellfun(@(x) isempty(x),HoldingPortfolio(:,1),'UniformOutput',0);
stL = cell2mat(stL);
stL = find(stL==0,1,'first');
% HoldingPortfolio里面的品种代码要加上月份信息
HoldingPortfolio = HoldingPortfolio(stL:end,:);
for d = 1:length(HoldingPortfolio)
    dateI = HoldingPortfolio{d,2};
    % 导入主力合约代码
    load([futMainContPath,'\',num2str(dateI),'.mat'])
    futcont = regexp(maincont(:,1),'\w*(?=\.)','match');
    futcont = reshape([futcont{:}],size(futcont));
    maincont = regexp(maincont(:,2),'\w*(?=\.)','match');
    maincont = reshape([maincont{:}],size(maincont)); 
    tmp = HoldingPortfolio{d,1};
    futI = tmp(:,1);
    [~,li0,li1] = intersect(futI,futcont);

    
    tmp(li0,1) = maincont(li1);
    HoldingPortfolio{d,1} = tmp;
end
    
Portfolio.HoldingPortfolio = HoldingPortfolio;
Portfolio.HoldingWeight = HoldingWeight(stL:end,:);

   
    

        
            
        
        
        
        

    
    
    
    



