function HoldingList = getHoldings(factorDate,PFactor,TradePara,PGlobal)
% 确定每期持仓的品种和方向

% 整体参数
TestType = PGlobal.TestType;
IndustryChoice = PGlobal.IndustryChoice;
% 路径
FactorPath = PFactor.FactorPath;
futLiquidPath = TradePara.futLiquidPath;
futSectorPath = TradePara.futSectorPath;
% 导入该板块对应的品种
load(futSectorPath,IndustryChoice)
str = ['SectorInfo = ',IndustryChoice,';'];
eval(str)
TradeList = cell(length(factorDate),2); %记录交易品种和交易方向
TradeList(:,2) = num2cell(factorDate);
if strcmp(TestType,'hedge')
    GroupList = cell(length(factorDate),2); %记录分组情况
    GroupList(:,2) = num2cell(factorDate);
end
for td = 1:length(factorDate) %逐个调仓日,注意factorDate中记录的是调仓日的前一日
    dateI = factorDate(td);   
    load([FactorPath,'\',num2str(dateI),'.mat']) % 导入因子数据
    % 品种筛选
    factorData(isnan(cell2mat(factorData(:,2))),:) = []; %剔除因子值缺失的品种
    if isempty(factorData) %当天所有品种的因子值均缺失
        continue;
    end
    [~,~,li0] = intersect(SectorInfo,factorData(:,1)); %剔除非该板块内的品种
    factorData = factorData(li0,:);
    if isempty(factorData) %没有该板块内的品种
        continue;
    end
    load([futLiquidPath,'\',num2str(dateI),'.mat']) %剔除流动性差的品种
    [~,~,li0] = intersect(liquidityInfo,factorData(:,1));
    factorData = factorData(li0,:);
    if isempty(factorData) %没有满足流动性要求的品种
        continue;
    end
    if strcmp(TestType,'hedge') %采用套利方式回测
        GroupNum = PFactor.GroupNum;
        if size(factorData,1)<GroupNum %当天可选的品种数少于分组数
            continue;
        end
    end
    % 确定各个品种持仓
    futFactor = factorData(:,1);
    futData = cell2mat(factorData(:,2));
    if strcmp(TestType,'trend') %趋势类
        TrendThr = PFactor.TrendThr;
        LongDirect = PFactor.LongDirect;
        holdings = zeros(length(futData),1);
        if strcmp(LongDirect,'max')
            holdings(futData>TrendThr(1)) = 1;
            holdings(futData<TrendThr(2)) = -1;
        else
            holdings(futData>TrendThr(1)) = -1;
            holdings(futData<TrendThr(2)) = 1;
        end
        holdingTD = [futFactor,num2cell(holdings)];
        holdingTD(holdings==0,:) = [];
    elseif strcmp(TestType,'hedge') %套利类
        GroupNum = PFactor.GroupNum; %分组数
        LongDirect = PFactor.LongDirect;
        num = length(futData);
        futnum = floor(num/GroupNum); %各组的期货个数
        remnum = rem(num,GroupNum); %余数
        med = num/2; %中位数所在位置
        if med==floor(med)
            med = med+1;
        else
            med = med+0.5;
        end
        [~,locs] = sort(futData); %升序排列
        futData = futData(locs);
        futFactor = futFactor(locs);
        if remnum~=0 %有余数
            if rem(remnum,2)==0 %偶数
                dltLocs = med-remnum/2+1:med+remnum/2;
            else %偶数
                dltLocs = med-(remnum-1)/2:med+(remnum-1)/2;
            end
            dltLocs = unique(dltLocs);
            futFactor(dltLocs) = [];
            futData(dltLocs) = [];
        end 
        locs = 1:length(futData);
        cutline = [0;cumsum(futnum*ones(GroupNum,1))];
        Groupings = zeros(length(futData),1);
        for gn = 1:GroupNum
            Groupings(locs(cutline(gn)+1:cutline(gn+1))) = gn;
        end
        holdingTD = cell(2*futnum,2);
        holdingTD(:,1) = [futFactor(Groupings==1);futFactor(Groupings==GroupNum)];
        if strcmp(LongDirect,'max') %做多最后一组
            holdingTD(1:futnum,2) = num2cell(-ones(futnum,1));
            holdingTD(futnum+1:end,2) = num2cell(ones(futnum,1));
        else
            holdingTD(1:futnum,2) = num2cell(ones(futnum,1));
            holdingTD(futnum+1:end,2) = num2cell(-ones(futnum,1));
        end
        Groupings = [futFactor,num2cell(Groupings)];
        GroupList{td,1} = Groupings;
    end
    TradeList{td,1} = holdingTD;
end
HoldingList.TradeList = TradeList;
if strcmp(TestType,'hedge')
    HoldingList.GroupList = GroupList;
end
    
        
            
            
        
        
        
        
        
        


