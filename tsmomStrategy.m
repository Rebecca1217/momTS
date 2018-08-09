% rankingPeriod 排序期
% holdingPeriod 持有期
% volScalingType:0 等权 1 ATR倒数加权  2 波动率倒数加权 3 目标波动率20% 4 目标波动率30% 5 目标波动率 40%
% volScalingDays 估计波动率的时-间窗口
% smoothingType 0 不平滑 1 平滑
% trdFeeType 0 不扣费 1 扣费 2 扣费和1个滑点
% enterPriceType 0 次日开盘价 1 次日收盘价 2 当日收盘价
signalType = 'tsmom';
rankingPeriod = 10;
holdingPeriod = 5;
type = 'winner - loser';
tsType = 3;
smoothingType = 1;
volScalingType = 0;
volScalingDays = 86;
smoothingType = 1;
trdFeeType = 1;
enterPriceType = 2;  %报告里采用当日收盘成交

initialEquity = 1000000000;%初始资金
marginRatio = 0.2;%保证金率
PositionRatio = 0.2; %仓位50%
slippage = 0;
tradingCost = 0.0003; %交易成本

pathNum = 5;  %路径数量

gap = holdingPeriod/5;
startIdxList = [0:4]*gap+1;

dynamicEquityMat = [];
tradeRecordMat = [];
turnoverRatioRecordMat = [];
amountHoldingSum = 0;


if ~enterPriceType  %以次日开盘价成交
    
    for k = 1 : pathNum
        
        n = startIdxList(k) + 1;
        % profile on
        
        cash = repmat(initialEquity,length(tradeCalendar),1); %可用资金
        dynamicEquity = repmat(initialEquity,length(tradeCalendar),1); %动态权益
        longMargin = zeros(length(tradeCalendar),1); %多头保证金
        shortMargin = zeros(length(tradeCalendar),1); %空头保证金
        holdingContractValue = zeros(length(tradeCalendar),1); %持仓合约价值
        positionDirection  = zeros(length(tradeCalendar),length(commodityDataCell(1,:))); %持仓方向
        positionHolding = zeros(length(tradeCalendar),length(commodityDataCell(1,:))); %持仓手数
        tradingLotsPerContLastTerm = zeros(1,length(commodityDataCell)); %上一期的持仓手数
        scale = cellfun(@(x) ( x.scale),commodityDataCell(2,:));
        currSignal = zeros(1,length(commodityDataCell)); %当前持仓方向
        monthChangeRecord = [];  %换月记录
        turnoverRatioRecord = []; %换手率记录
        
        tradeRecord = []; %记录每一期的表现，放在summary中分析
        currTermReturn = zeros(1,length(commodityDataCell)); %本期各品种的收益
        entryPrice = zeros(1,length(commodityDataCell)); %本期各品种的开仓价格
        entryAdjPrice = entryPrice;
        
        beginIdx = max(rankingPeriod,holdingPeriod ) + n - 1;
        
        for i = beginIdx : length(tradeCalendar)
            
            currTradeDate = tradeCalendar(i);
            cash(i) =cash(i-1);
            currHoldingContData = commodityDataCell(2,currSignal~=0);
            currPosition = tradingLotsPerContLastTerm(tradingLotsPerContLastTerm~=0);
            positionHolding(i,:) = tradingLotsPerContLastTerm;
            commodityIdx = find(tradingLotsPerContLastTerm);
            
            %换仓日
            if rem(i - beginIdx -1 ,holdingPeriod) == 0 & i < length(tradeCalendar)
                
                %开盘盈亏 主力合约不连续 须由收益率倒推
                holdingValueChange =  cellfun(@(x) ( x.dominant_Data(x.tradeCalendar == currTradeDate,...
                    2)),currHoldingContData).*(1 - cellfun(@(x) (x.dominant_Adjusted_Data(x.tradeCalendar == currTradeDate,2)/x.dominant_Adjusted_Data(x.tradeCalendar == tradeCalendar(i-1),5)),...
                    currHoldingContData)).*scale(currSignal~=0).*currPosition;
                
                
                if ~isempty(holdingValueChange)
                    
                    longMargin(i) = longMargin(i-1) +   sum(holdingValueChange(currPosition>0));
                    shortMargin(i) = shortMargin(i-1)  +   sum(holdingValueChange(currPosition<0));
                    dynamicEquity(i) =  cash(i)  + longMargin(i) + shortMargin(i); %现金+多头保证金+空头保证金
                    
                end
                
                %当前持仓价值
                holdingContractValue(i) = (longMargin(i) + shortMargin(i))*(1/marginRatio);
                
                
                %首先记录平仓价位
                closeAdjPrice = cellfun(@(x) ( x.dominant_Adjusted_Data(x.tradeCalendar == tradeCalendar(i),...
                    2)),commodityDataCell(2,currSignal~=0));
                
                if sum(entryAdjPrice) > 0
                    %上一期的收益率
                    currCommodityReturn = closeAdjPrice./entryAdjPrice - 1;%涨跌幅
                    currCommodityReturn = currCommodityReturn.*currSignal(currSignal~=0);%涨跌幅*仓位
                    %当期收益记录
                    currCommodityReturnCell = [ commodityDataCell(1,currSignal~=0);num2cell(currSignal(currSignal~=0));num2cell(currCommodityReturn);num2cell(tempScale'/length(tempScale))];
                    currCommodityReturnCell = sortrows(currCommodityReturnCell',-3)';
                    
                    if ~volScalingType
                        %等权重
                        currTermRecord = {currTermStartDate ; currTradeDate;  mean(currCommodityReturn);...
                            currCommodityReturnCell};
                    else
                        %波动率加权
                        currTermRecord = {currTermStartDate ; currTradeDate; sum((currCommodityReturn).*(tempScale'/length(tempScale))) ;...
                            currCommodityReturnCell};
                    end
                    tradeRecord = [tradeRecord , currTermRecord];
                end
                
                currTermStartDate = currTradeDate;
                
                if strcmpi(signalType,'tsmom')
                    currSignal = tsmomSignalGenerator(tradeCalendar(i-1),rankingPeriod,type);  %当前交易信号  时间序列动量
                elseif  strcmpi(signalType,'xmom')
                    currSignal = xmomSignalGenerator(tradeCalendar(i-1),rankingPeriod,type,volScalingDays);  %当前交易信号  横截面动量
                elseif strcmpi(signalType,'ts')
                    currSignal = tsSignalGenerator(tradeCalendar(i-1) ,tsType ,type) ; %当前交易信号  期限结构
                    %currSignal = tsSignalGenerator(currTradeDate,rankingPeriod,type);  %当前交易信号  期限结构
                elseif strcmpi(signalType,'mix')
                    currSignal = mixSignalGenerator(tradeCalendar(i-1),rankingPeriod,tsType,firstSortingFactor,type,volScalingDays);  %当前交易信号  混合
                else
                    currSignal = eqwSignalGenerator(tradeCalendar(i-1),rankingPeriod);  %当前交易信号  等权配置
                end
                
                positionDirection(i,:) = currSignal;
                
                %交易的合约价值
                tradingValue = dynamicEquity(i) * PositionRatio * (1 / marginRatio);
                tradingValue = dynamicEquity(i);
                tradingValuePerCont =  tradingValue/length(currSignal(currSignal~=0));
                
                if volScalingType == 0
                    
                    tempScale = ones(length(currSignal(currSignal~=0)),1);
                    tempScale(1:end) = 1;
                    
                elseif volScalingType == 1
                    
                    %ATR
                    ATRList = [];
                    %%%%%使用ATR进行调整  60日普通波动率
                    for p = 1 : length(commodityDataCell)
                        if abs(currSignal(p))>0
                            currCommdityData  =  commodityDataCell{2,p}.dominant_Adjusted_Data;
                            idx = find(  currCommdityData(:,1)<=tradeCalendar(i),1,'last');
                            temp = currCommdityData(idx -volScalingDays  : idx , :);
                            ATRList = [ATRList;calc_ATR(temp(:,3),temp(:,4),temp(:,5),volScalingDays)/temp(end,5)];
                            %volList = [volList;calc_vol(currCommdityData(idx -60 +1 : idx , end),60/61)];
                        end
                    end
                    volList = ATRList;
                    tradingValuePerContAdjustedbyVol = tradingValue*1./volList/sum(1./volList);
                    tempScale = tradingValuePerContAdjustedbyVol/tradingValuePerCont;
                    
                else
                    volList = [];
                    retList = [];
                    %%%%%%使用波动率进行调整  60日普通波动率
                    for p = 1 : length(commodityDataCell)
                        if abs(currSignal(p))>0
                            currCommdityData  =  commodityDataCell{2,p}.dominant_Adjusted_Data;
                            idx = find(  currCommdityData(:,1)<=tradeCalendar(i),1,'last');
                            temp = currCommdityData(idx -volScalingDays +1 : idx , :);
                            %volList = [volList;std(temp(:,end))*sqrt(242)];
                            volList = [volList;calc_vol(currCommdityData(idx -volScalingDays +1 : idx , end),0.94)];
                            retList = [retList ,currCommdityData(idx -volScalingDays +1 : idx , end)];
                        end
                    end
                    %波动率倒数加权
                    tradingValuePerContAdjustedbyVol = tradingValue*1./volList/sum(1./volList);
                    
                    if volScalingType == 3
                        %将波动率调整到同一水平
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.2./volList;
                    elseif volScalingType == 4
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.3./volList;
                    elseif volScalingType == 5
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.4./volList;
                        
                        % 考虑相关系数  相关系数调整
                    elseif volScalingType == 6
                        N = length(volList);
                        [~,ExpCorrC]=cov2corr(cov(retList));
                        avgCorr = (sum(sum(ExpCorrC)) - sum(diag(ExpCorrC)))/(N*(N-1));
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.1./volList*sqrt(N/(1+(N-1)*avgCorr));
                        
                    elseif volScalingType == 7
                        N = length(volList);
                        [~,ExpCorrC]=cov2corr(cov(retList));
                        avgCorr = (sum(sum(ExpCorrC)) - sum(diag(ExpCorrC)))/(N*(N-1));
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.2./volList*sqrt(N/(1+(N-1)*avgCorr));
                        
                    elseif volScalingType == 8
                        
                        PortWts = (currSignal(currSignal~=0))/sum(abs(currSignal));
                        ExpReturn = zeros(size(PortWts));
                        [~,ExpCorrC]=cov2corr(cov(retList));
                        [PortRisk , PortReturn] =portstats( ExpReturn, ExpCorrC , PortWts);
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.1./volList/PortRisk;
                        
                        
                    elseif volScalingType == 9
                        
                        PortWts = (currSignal(currSignal~=0))/sum(abs(currSignal));
                        ExpReturn = zeros(size(PortWts));
                        [~,ExpCorrC]=cov2corr(cov(retList));
                        [PortRisk , PortReturn] =portstats( ExpReturn, ExpCorrC , PortWts);
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.2./volList/PortRisk;
                        
                        
                    elseif volScalingType == 10
                        N = length(volList);
                        covMatrix = cov(retList);
                        weight = fmincon(@(x) riskParityFunc(x,covMatrix),1./volList/sum(1./volList), [],[],ones(1,N) ,1);
                        %tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.2./volList*sqrt(N/(1+(N-1)*avgCorr));
                        tradingValuePerContAdjustedbyVol = tradingValue.*weight;
                        
                    end
                    tempScale = tradingValuePerContAdjustedbyVol/tradingValuePerCont;
                end
                
                
                %每个合约建仓价格 真实价格 用于计算资金   第二天开盘价
                entryPrice =cellfun(@(x) ( x.dominant_Data(x.tradeCalendar == tradeCalendar(i),...
                    2)),commodityDataCell(2,currSignal~=0));
                %每个合约建仓价格 复权价格  用于计算收益
                entryAdjPrice =cellfun(@(x) ( x.dominant_Adjusted_Data(x.tradeCalendar == tradeCalendar(i),...
                    2)),commodityDataCell(2,currSignal~=0));
                
                %每个合约交易手数 波动率加权
                %开盘价
                tradingLots = round( tempScale'.* cellfun(@(x) ( tradingValuePerCont/x.scale/x.dominant_Data(x.tradeCalendar == tradeCalendar(i+1),...
                    2)),commodityDataCell(2,currSignal~=0)));
                
                %每个合约换手情况
                tradingLotsPerCont = currSignal;
                tradingLotsPerCont(currSignal~=0) =  tradingLotsPerCont(currSignal~=0).*tradingLots;
                tradingLotsTurnover = tradingLotsPerCont - tradingLotsPerContLastTerm;
                
                %滑点成本  按1跳来计算
                slippageCost =sum(cellfun(@(x) (x.scale.*x.minPriceChg),commodityDataCell(2,:)).*abs(tradingLotsTurnover))*slippage;
                
                tradingValueTurnover = sum(cellfun(@(x) ( x.scale*x.dominant_Data(x.tradeCalendar == currTradeDate,...
                    5)),commodityDataCell(2,tradingLotsTurnover~=0)).* abs(tradingLotsTurnover(tradingLotsTurnover~=0)));
                tradingLotsPerContLastTerm = tradingLotsPerCont;
                %当期换手率写入矩阵
                turnoverRatioRecord = [turnoverRatioRecord ; [currTradeDate , tradingValueTurnover/holdingContractValue(i)/2]];
                %静态权益扣手续费
                %staticEquity(i) = staticEquity(i) - tradingValueTurnover*tradingCost;
                temp = tradingLotsPerCont(tradingLotsPerCont~=0);
                currScale = cellfun(@(x) (x.scale),commodityDataCell(2,currSignal~=0));
                currMinPriceChg= cellfun(@(x) (x.minPriceChg),commodityDataCell(2,currSignal~=0));
                currHoldingValue = entryPrice.*tradingLots.*currScale;
                %多头保证金
                longMargin(i) = sum(currHoldingValue(temp>0))*marginRatio;
                %空头保证金
                shortMargin(i) = sum(currHoldingValue(temp<0)).*marginRatio;
                cash(i) = dynamicEquity(i) -  longMargin(i) -  shortMargin(i) - tradingValueTurnover*tradingCost - slippageCost;
                
                %持有至收盘结算
                holdingValueChange =  cellfun(@(x) ( x.dominant_Data(x.tradeCalendar == currTradeDate,...
                    5) - x.dominant_Data(x.tradeCalendar == currTradeDate,2)),commodityDataCell(2,currSignal~=0)).*scale(currSignal~=0).* tradingLotsPerCont(currSignal~=0);
                %end
                
                currPosition = tradingLotsPerContLastTerm(tradingLotsPerContLastTerm~=0);
                
                if ~isempty(holdingValueChange)
                    
                    longMargin(i) = longMargin(i) +   sum(holdingValueChange(currPosition>0));
                    shortMargin(i) = shortMargin(i)  +   sum(holdingValueChange(currPosition<0));
                    dynamicEquity(i) =  cash(i)  + longMargin(i) + shortMargin(i); %现金+多头保证金+空头保证金
                    
                end
                %当前持仓价值
                holdingContractValue(i) = (longMargin(i) + shortMargin(i))*(1/marginRatio);
                
            else
                %非调仓日  主力合约不连续，须由收益率倒推
                holdingValueChange =  cellfun(@(x) ( x.dominant_Data(x.tradeCalendar == currTradeDate,...
                    5)),currHoldingContData).*(1 - (1./(1 +  cellfun(@(x) (x.dominant_Adjusted_Data(x.tradeCalendar == currTradeDate,end)),...
                    currHoldingContData)))).*scale(currSignal~=0).*currPosition;
                
                if ~isempty(holdingValueChange)
                    
                    longMargin(i) = longMargin(i-1) +   sum(holdingValueChange(currPosition>0)*marginRatio);
                    shortMargin(i) = shortMargin(i-1)  +   sum(holdingValueChange(currPosition<0)*marginRatio);
                    cash(i) = cash(i) + sum(holdingValueChange)*(1 - marginRatio);
                    dynamicEquity(i) =  cash(i)  + longMargin(i) + shortMargin(i); %现金+多头保证金+空头保证金
                    
                    % 合约换月处理
                    for j = 1 : length(currHoldingContData)
                        
                        tempPostion = currPosition(j);
                        temp = currHoldingContData{1,j}.changeMonth_Data;
                        idx = find(temp(:,1) == currTradeDate);
                        
                        if ~isempty(idx)
                            
                            temp = temp(idx,:);
                            if isnan(temp(3))
                                temp(3) = currHoldingContData{1,j}.dominant_Data(currHoldingContData{1,j}.dominant_Data(:,1) == currTradeDate , 5);
                            end
                            valueClose =  temp(3)*currScale(j)*currPosition(j);
                            lotsClose = currPosition(j) ;
                            currPosition(j) = round(valueClose/temp(5)/currScale(j));
                            valueOpen = temp(5)*currScale(j)*currPosition(j);
                            holdingValueChange = abs(valueOpen) - abs(valueClose); %仓位变动
                            
                            if tempPostion > 0
                                longMargin(i) =  longMargin(i)  + holdingValueChange*marginRatio;
                                cash(i) = cash(i) - holdingValueChange*marginRatio;
                            else
                                shortMargin(i) =  shortMargin(i)  + holdingValueChange*marginRatio;
                                cash(i) = cash(i) - holdingValueChange*marginRatio;
                            end
                            %计算滑点 开平各1跳
                            slippageCost = (abs(lotsClose) + abs(currPosition(j)))*currScale(j)*currMinPriceChg(j)*slippage;
                            cash(i) = cash(i) - (abs(valueClose) + abs(valueOpen)) *tradingCost - slippageCost;
                            monthChangeRecord = [monthChangeRecord; [currTradeDate , commodityIdx(j) , temp(2:5),  ...
                                lotsClose,currPosition(j) ,(abs(valueClose) + abs(valueOpen)) *tradingCost + slippageCost ]];
                            dynamicEquity(i) =  cash(i)  + longMargin(i) + shortMargin(i); %现金+多头保证金+空头保证金
                        end
                    end
                    %动态权益，此处即为总权益
                    %dynamicEquity(i) =  cash(i)  + longMargin(i) + shortMargin(i); %现金+多头保证金+空头保证金
                end
                %当前持仓价值
                holdingContractValue(i) = (longMargin(i) + shortMargin(i))*(1/marginRatio);
            end
            
            %剩下的资金放回购
            cash(i) = cash(i)*(1 + repoOvernight(i)/360);
            %disp(i)
        end  %loop i
        %profile viewer
        dynamicEquity = dynamicEquity/dynamicEquity(1);
        dynamicEquityMat = [dynamicEquityMat, dynamicEquity];
        tradeRecordMat = [tradeRecordMat, tradeRecord];
        %disp(n)
    end
    
elseif enterPriceType == 1 %以次日收盘价成交
    
    for k = 1 : pathNum
        
        n = startIdxList(k)+1;
        
        cash = repmat(initialEquity,length(tradeCalendar),1); %可用资金
        dynamicEquity = repmat(initialEquity,length(tradeCalendar),1); %动态权益
        longMargin = zeros(length(tradeCalendar),1); %多头保证金
        shortMargin = zeros(length(tradeCalendar),1); %空头保证金
        holdingContractValue = zeros(length(tradeCalendar),1); %持仓合约价值
        positionDirection  = zeros(length(tradeCalendar),length(commodityDataCell(1,:))); %持仓方向
        positionHolding = zeros(length(tradeCalendar),length(commodityDataCell(1,:))); %持仓手数
        tradingLotsPerContLastTerm = zeros(1,length(commodityDataCell)); %上一期的持仓手数
        scale = cellfun(@(x) ( x.scale),commodityDataCell(2,:));
        currSignal = zeros(1,length(commodityDataCell)); %当前持仓方向
        monthChangeRecord = [];  %换月记录
        turnoverRatioRecord = []; %换手率记录
        
        tradeRecord = []; %记录每一期的表现，放在summary中分析
        currTermReturn = zeros(1,length(commodityDataCell)); %本期各品种的收益
        entryPrice = zeros(1,length(commodityDataCell)); %本期各品种的开仓价格
        entryAdjPrice = entryPrice;
        
        beginIdx = max(rankingPeriod,holdingPeriod ) + n - 1;
        
        for i = beginIdx : length(tradeCalendar)
            
            currTradeDate = tradeCalendar(i);
            cash(i) =cash(i-1);
            currHoldingContData = commodityDataCell(2,currSignal~=0);
            currPosition = tradingLotsPerContLastTerm(tradingLotsPerContLastTerm~=0);
            positionHolding(i,:) = tradingLotsPerContLastTerm;
            commodityIdx = find(tradingLotsPerContLastTerm);
            
            
            holdingValueChange =  cellfun(@(x) ( x.dominant_Data(x.tradeCalendar == currTradeDate,...
                5)),currHoldingContData).*(1 - (1./(1 +  cellfun(@(x) (x.dominant_Adjusted_Data(x.tradeCalendar == currTradeDate,end)),...
                currHoldingContData)))).*scale(currSignal~=0).*currPosition;
            
            
            if ~isempty(holdingValueChange)
                
                longMargin(i) = longMargin(i-1) +   sum(holdingValueChange(currPosition>0)*marginRatio);
                shortMargin(i) = shortMargin(i-1)  +   sum(holdingValueChange(currPosition<0)*marginRatio);
                cash(i) = cash(i) + sum(holdingValueChange)*(1 - marginRatio);
                dynamicEquity(i) =  cash(i)  + longMargin(i) + shortMargin(i); %现金+多头保证金+空头保证金
                
                % 合约换月处理
                for j = 1 : length(currHoldingContData)
                    
                    tempPostion = currPosition(j);
                    temp = currHoldingContData{1,j}.changeMonth_Data;
                    idx = find(temp(:,1) == currTradeDate);
                    
                    if ~isempty(idx)
                        
                        temp = temp(idx,:);
                        if isnan(temp(3))
                            temp(3) = currHoldingContData{1,j}.dominant_Data(currHoldingContData{1,j}.dominant_Data(:,1) == currTradeDate , 5);
                        end
                        valueClose =  temp(3)*currScale(j)*currPosition(j);
                        lotsClose = currPosition(j) ;
                        currPosition(j) = round(valueClose/temp(5)/currScale(j));
                        valueOpen = temp(5)*currScale(j)*currPosition(j);
                        holdingValueChange = abs(valueOpen) - abs(valueClose); %仓位变动
                        
                        if tempPostion > 0
                            longMargin(i) =  longMargin(i)  + holdingValueChange*marginRatio;
                            cash(i) = cash(i) - holdingValueChange*marginRatio;
                        else
                            shortMargin(i) =  shortMargin(i)  + holdingValueChange*marginRatio;
                            cash(i) = cash(i) - holdingValueChange*marginRatio;
                        end
                        %计算滑点 开平各1跳
                        slippageCost = (abs(lotsClose) + abs(currPosition(j)))*currScale(j)*currMinPriceChg(j)*slippage;
                        cash(i) = cash(i) - (abs(valueClose) + abs(valueOpen)) *tradingCost - slippageCost;
                        monthChangeRecord = [monthChangeRecord; [currTradeDate , commodityIdx(j) , temp(2:5),  ...
                            lotsClose,currPosition(j) ,(abs(valueClose) + abs(valueOpen)) *tradingCost + slippageCost ]];
                        dynamicEquity(i) =  cash(i)  + longMargin(i) + shortMargin(i); %现金+多头保证金+空头保证金
                    end
                end
            end
            
            %当前持仓价值
            holdingContractValue(i) = (longMargin(i) + shortMargin(i))*(1/marginRatio);
            
            %换仓日
            if rem(i - beginIdx ,holdingPeriod) == 0 & i < length(tradeCalendar)
                
                %首先记录平仓价位
                closeAdjPrice = cellfun(@(x) ( x.dominant_Adjusted_Data(x.tradeCalendar == currTradeDate,...
                    5)),commodityDataCell(2,currSignal~=0));
                if sum(entryAdjPrice) > 0
                    %上一期的收益率
                    currCommodityReturn = closeAdjPrice./entryAdjPrice - 1;%涨跌幅
                    currCommodityReturn = currCommodityReturn.*currSignal(currSignal~=0);%涨跌幅*仓位
                    
                    %当期收益记录
                    currCommodityReturnCell = [ commodityDataCell(1,currSignal~=0);num2cell(currSignal(currSignal~=0));num2cell(currCommodityReturn);num2cell(tempScale'/sum(tempScale))];
                    currCommodityReturnCell = sortrows(currCommodityReturnCell',-3)';
                    
                    currTermRecord = {currTermStartDate ; currTradeDate; sum((1+currCommodityReturn).*tempScale')/sum(tempScale)-1 ;...
                        currCommodityReturnCell};
                    tradeRecord = [tradeRecord , currTermRecord];
                    
                end
                
                currTermStartDate = currTradeDate;
                
                if strcmpi(signalType,'tsmom')
                    currSignal = tsmomSignalGenerator(tradeCalendar(i-1),rankingPeriod,type);  %当前交易信号  时间序列动量
                elseif  strcmpi(signalType,'xmom')
                    currSignal = xmomSignalGenerator(tradeCalendar(i-1),rankingPeriod,type,volScalingType,volScalingDays);  %当前交易信号  横截面动量
                elseif strcmpi(signalType,'ts')
                    currSignal = tsSignalGenerator(tradeCalendar(i-1) ,tsType ,type) ; %当前交易信号  期限结构
                    %currSignal = tsSignalGenerator(currTradeDate,rankingPeriod,type);  %当前交易信号  期限结构
                elseif strcmpi(signalType,'mix')
                    currSignal = mixSignalGenerator(tradeCalendar(i-1),rankingPeriod,tsType,firstSortingFactor,type,volScalingDays);  %当前交易信号  混合
                else
                    currSignal = eqwSignalGenerator(tradeCalendar(i-1),rankingPeriod);  %当前交易信号  等权配置
                end
                
                positionDirection(i,:) = currSignal;
                
                %交易的合约价值
                tradingValue = dynamicEquity(i) * PositionRatio * (1 / marginRatio);
                tradingValue = dynamicEquity(i);
                tradingValuePerCont =  tradingValue/length(currSignal(currSignal~=0));
                
                if volScalingType == 0
                    
                    tempScale = ones(length(currSignal(currSignal~=0)),1);
                    tempScale(1:end) = 1;
                    
                elseif volScalingType == 1
                    
                    %ATR
                    ATRList = [];
                    %%%%%使用ATR进行调整  60日普通波动率
                    for p = 1 : length(commodityDataCell)
                        if abs(currSignal(p))>0
                            currCommdityData  =  commodityDataCell{2,p}.dominant_Adjusted_Data;
                            idx = find(  currCommdityData(:,1)<=tradeCalendar(i),1,'last');
                            temp = currCommdityData(idx -volScalingDays  : idx , :);
                            ATRList = [ATRList;calc_ATR(temp(:,3),temp(:,4),temp(:,5),volScalingDays)/temp(end,5)];
                            %volList = [volList;calc_vol(currCommdityData(idx -60 +1 : idx , end),60/61)];
                        end
                    end
                    volList = ATRList;
                    tradingValuePerContAdjustedbyVol = tradingValue*1./volList/sum(1./volList);
                    tempScale = tradingValuePerContAdjustedbyVol/tradingValuePerCont;
                    
                else
                    volList = [];
                    retList = [];
                    %%%%%%使用波动率进行调整  60日普通波动率
                    for p = 1 : length(commodityDataCell)
                        if abs(currSignal(p))>0
                            currCommdityData  =  commodityDataCell{2,p}.dominant_Adjusted_Data;
                            idx = find(  currCommdityData(:,1)<=tradeCalendar(i),1,'last');
                            temp = currCommdityData(idx -volScalingDays +1 : idx , :);
                            %volList = [volList;std(temp(:,end))*sqrt(242)];
                            volList = [volList;calc_vol(currCommdityData(idx -volScalingDays +1 : idx , end),0.94)];
                            retList = [retList ,currCommdityData(idx -volScalingDays +1 : idx , end)];
                        end
                    end
                    %波动率倒数加权
                    tradingValuePerContAdjustedbyVol = tradingValue*1./volList/sum(1./volList);
                    
                    if volScalingType == 3
                        %将波动率调整到同一水平
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.2./volList;
                    elseif volScalingType == 4
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.3./volList;
                    elseif volScalingType == 5
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.4./volList;
                        
                        % 考虑相关系数  相关系数调整
                    elseif volScalingType == 6
                        N = length(volList);
                        [~,ExpCorrC]=cov2corr(cov(retList));
                        avgCorr = (sum(sum(ExpCorrC)) - sum(diag(ExpCorrC)))/(N*(N-1));
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.1./volList*sqrt(N/(1+(N-1)*avgCorr));
                        
                    elseif volScalingType == 7
                        N = length(volList);
                        [~,ExpCorrC]=cov2corr(cov(retList));
                        avgCorr = (sum(sum(ExpCorrC)) - sum(diag(ExpCorrC)))/(N*(N-1));
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.2./volList*sqrt(N/(1+(N-1)*avgCorr));
                        
                    elseif volScalingType == 8
                        
                        PortWts = (currSignal(currSignal~=0))/sum(abs(currSignal));
                        ExpReturn = zeros(size(PortWts));
                        [~,ExpCorrC]=cov2corr(cov(retList));
                        [PortRisk , PortReturn] =portstats( ExpReturn, ExpCorrC , PortWts);
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.1./volList/PortRisk;
                        
                        
                    elseif volScalingType == 9
                        
                        PortWts = (currSignal(currSignal~=0))/sum(abs(currSignal));
                        ExpReturn = zeros(size(PortWts));
                        [~,ExpCorrC]=cov2corr(cov(retList));
                        [PortRisk , PortReturn] =portstats( ExpReturn, ExpCorrC , PortWts);
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.2./volList/PortRisk;
                        
                        
                    elseif volScalingType == 10
                        N = length(volList);
                        covMatrix = cov(retList);
                        weight = fmincon(@(x) riskParityFunc(x,covMatrix),1./volList/sum(1./volList), [],[],ones(1,N) ,1);
                        %tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.2./volList*sqrt(N/(1+(N-1)*avgCorr));
                        tradingValuePerContAdjustedbyVol = tradingValue.*weight;
                        
                    end
                    tempScale = tradingValuePerContAdjustedbyVol/tradingValuePerCont;
                end
                
                
                %每个合约建仓价格 真实价格 用于计算资金   当天收盘价
                entryPrice =cellfun(@(x) ( x.dominant_Data(x.tradeCalendar == currTradeDate,...
                    5)),commodityDataCell(2,currSignal~=0));
                %每个合约建仓价格 复权价格  用于计算收益
                entryAdjPrice =cellfun(@(x) ( x.dominant_Adjusted_Data(x.tradeCalendar == currTradeDate,...
                    5)),commodityDataCell(2,currSignal~=0));
                
                tradingLots = round( tempScale'.* cellfun(@(x) ( tradingValuePerCont/x.scale/x.dominant_Data(x.tradeCalendar == currTradeDate,...
                    5)),commodityDataCell(2,currSignal~=0)));
                
                
                %每个合约换手情况
                tradingLotsPerCont = currSignal;
                tradingLotsPerCont(currSignal~=0) =  tradingLotsPerCont(currSignal~=0).*tradingLots;
                tradingLotsTurnover = tradingLotsPerCont - tradingLotsPerContLastTerm;
                
                %滑点成本  按1跳来计算
                slippageCost =sum(cellfun(@(x) (x.scale.*x.minPriceChg),commodityDataCell(2,:)).*abs(tradingLotsTurnover))*slippage;
                
                tradingValueTurnover = sum(cellfun(@(x) ( x.scale*x.dominant_Data(x.tradeCalendar == currTradeDate,...
                    5)),commodityDataCell(2,tradingLotsTurnover~=0)).* abs(tradingLotsTurnover(tradingLotsTurnover~=0)));
                tradingLotsPerContLastTerm = tradingLotsPerCont;
                %当期换手率写入矩阵
                turnoverRatioRecord = [turnoverRatioRecord ; [currTradeDate , tradingValueTurnover/holdingContractValue(i)/2]];
                %静态权益扣手续费
                %staticEquity(i) = staticEquity(i) - tradingValueTurnover*tradingCost;
                temp = tradingLotsPerCont(tradingLotsPerCont~=0);
                currScale = cellfun(@(x) (x.scale),commodityDataCell(2,currSignal~=0));
                currMinPriceChg= cellfun(@(x) (x.minPriceChg),commodityDataCell(2,currSignal~=0));
                currHoldingValue = entryPrice.*tradingLots.*currScale;
                %多头保证金
                longMargin(i) = sum(currHoldingValue(temp>0))*marginRatio;
                %空头保证金
                shortMargin(i) = sum(currHoldingValue(temp<0)).*marginRatio;
                cash(i) = dynamicEquity(i) -  longMargin(i) -  shortMargin(i) - tradingValueTurnover*tradingCost - slippageCost;
            end
            %剩下的资金放回购
            cash(i) = cash(i)*(1 + repoOvernight(i)/360);
            %disp(i)
        end  %loop i
        %profile viewer
        dynamicEquity = dynamicEquity/dynamicEquity(1);
        dynamicEquityMat = [dynamicEquityMat, dynamicEquity];
        tradeRecordMat = [tradeRecordMat, tradeRecord];
    end
    
else %以当日收盘价成交
    
    for k = 1 : pathNum
        
        n = startIdxList(k)+1;
        
        cash = repmat(initialEquity,length(tradeCalendar),1); %可用资金
        dynamicEquity = repmat(initialEquity,length(tradeCalendar),1); %动态权益
        longMargin = zeros(length(tradeCalendar),1); %多头保证金
        shortMargin = zeros(length(tradeCalendar),1); %空头保证金
        holdingContractValue = zeros(length(tradeCalendar),1); %持仓合约价值
        positionDirection  = zeros(length(tradeCalendar),length(commodityDataCell(1,:))); %持仓方向
        positionHolding = zeros(length(tradeCalendar),length(commodityDataCell(1,:))); %持仓手数
        amountHolding = zeros(length(tradeCalendar),length(commodityDataCell(1,:)));    %持仓面额
        
        tradingLotsPerContLastTerm = zeros(1,length(commodityDataCell)); %上一期的持仓手数
        scale = cellfun(@(x) ( x.scale),commodityDataCell(2,:));
        currSignal = zeros(1,length(commodityDataCell)); %当前持仓方向
        monthChangeRecord = [];  %换月记录
        turnoverRatioRecord = []; %换手率记录
        
        tradeRecord = []; %记录每一期的表现，放在summary中分析
        currTermReturn = zeros(1,length(commodityDataCell)); %本期各品种的收益
        entryPrice = zeros(1,length(commodityDataCell)); %本期各品种的开仓价格
        entryAdjPrice = entryPrice;
        error
        beginIdx = max(rankingPeriod,holdingPeriod ) + n - 1;
        
        for i = beginIdx : length(tradeCalendar)
            
            currTradeDate = tradeCalendar(i);
            cash(i) =cash(i-1);
            currHoldingContData = commodityDataCell(2,currSignal~=0);
            currPosition = tradingLotsPerContLastTerm(tradingLotsPerContLastTerm~=0);
            positionHolding(i,:) = tradingLotsPerContLastTerm;
            commodityIdx = find(tradingLotsPerContLastTerm);
            
            amountHolding(i,currSignal~=0) = cellfun(@(x) ( x.dominant_Data(x.tradeCalendar == currTradeDate,...
                5)),currHoldingContData).*scale(currSignal~=0).*currPosition;
            
            holdingValueChange =  cellfun(@(x) ( x.dominant_Data(x.tradeCalendar == currTradeDate,...
                5)),currHoldingContData).*(1 - (1./(1 +  cellfun(@(x) (x.dominant_Adjusted_Data(x.tradeCalendar == currTradeDate,end)),...
                currHoldingContData)))).*scale(currSignal~=0).*currPosition;
            
            if ~isempty(holdingValueChange)
                
                longMargin(i) = longMargin(i-1) +   sum(holdingValueChange(currPosition>0)*marginRatio);
                shortMargin(i) = shortMargin(i-1)  +   sum(holdingValueChange(currPosition<0)*marginRatio);
                cash(i) = cash(i) + sum(holdingValueChange)*(1 - marginRatio); % 这里追加了保证金，可用资金不是应该减少？
                %
                % margin cash equity三者的转换关系是怎样的？
                % 我理解应该是cash出钱进保证金，那cash应该减少，权益应该增加吧 这块不太理解。。。
                dynamicEquity(i) =  cash(i)  + longMargin(i) + shortMargin(i); %现金+多头保证金+空头保证金
                
                % 合约换月处理
                for j = 1 : length(currHoldingContData)
                    
                    tempPostion = currPosition(j);
                    temp = currHoldingContData{1,j}.changeMonth_Data;
                    idx = find(temp(:,1) == currTradeDate);
                    
                    if ~isempty(idx)
                        
                        temp = temp(idx,:);
                        if isnan(temp(3))
                            temp(3) = currHoldingContData{1,j}.dominant_Data(currHoldingContData{1,j}.dominant_Data(:,1) == currTradeDate , 5);
                        end
                        valueClose =  temp(3)*currScale(j)*currPosition(j);
                        lotsClose = currPosition(j) ;
                        currPosition(j) = round(valueClose/temp(5)/currScale(j));
                        valueOpen = temp(5)*currScale(j)*currPosition(j);
                        holdingValueChange = abs(valueOpen) - abs(valueClose); %仓位变动
                        
                        if tempPostion > 0
                            longMargin(i) =  longMargin(i)  + holdingValueChange*marginRatio;
                            cash(i) = cash(i) - holdingValueChange*marginRatio;
                        else
                            shortMargin(i) =  shortMargin(i)  + holdingValueChange*marginRatio;
                            cash(i) = cash(i) - holdingValueChange*marginRatio;
                        end
                        %计算滑点 开平各1跳
                        slippageCost = (abs(lotsClose) + abs(currPosition(j)))*currScale(j)*currMinPriceChg(j)*slippage;
                        cash(i) = cash(i) - (abs(valueClose) + abs(valueOpen)) *tradingCost - slippageCost;
                        monthChangeRecord = [monthChangeRecord; [currTradeDate , commodityIdx(j) , temp(2:5),  ...
                            lotsClose,currPosition(j) ,(abs(valueClose) + abs(valueOpen)) *tradingCost + slippageCost ]];
                        dynamicEquity(i) =  cash(i)  + longMargin(i) + shortMargin(i); %现金+多头保证金+空头保证金
                    end
                end
            end
            
            %当前持仓价值
            holdingContractValue(i) = (longMargin(i) + shortMargin(i))*(1/marginRatio);
            
            %换仓日
            %%%%%%%%%%%%%下面是策略的核心部分，在换仓日的时候发出策略信号：
            if rem(i - beginIdx ,holdingPeriod) == 0 && i < length(tradeCalendar)
                
                %首先记录平仓价位
                closeAdjPrice = cellfun(@(x) ( x.dominant_Adjusted_Data(x.tradeCalendar == currTradeDate,...
                    5)),commodityDataCell(2,currSignal~=0));
                if sum(entryAdjPrice) > 0
                    %上一期的收益率
                    currCommodityReturn = closeAdjPrice./entryAdjPrice - 1;%涨跌幅
                    currCommodityReturn = currCommodityReturn.*currSignal(currSignal~=0);%涨跌幅*仓位
                    
                    %当期收益记录
                    currCommodityReturnCell = [ commodityDataCell(1,currSignal~=0);num2cell(currSignal(currSignal~=0));num2cell(currCommodityReturn);num2cell(tempScale'/sum(tempScale))];
                    currCommodityReturnCell = sortrows(currCommodityReturnCell',-3)';
                    
                    currTermRecord = {currTermStartDate ; currTradeDate; sum((1+currCommodityReturn).*tempScale')/sum(tempScale)-1 ;...
                        currCommodityReturnCell};
                    tradeRecord = [tradeRecord , currTermRecord];
                    
                end
                
                currTermStartDate = currTradeDate;
                
                if strcmpi(signalType,'tsmom')
                    currSignal = tsmomSignalGenerator(tradeCalendar(i),rankingPeriod,type);  %当前交易信号  时间序列动量
                elseif  strcmpi(signalType,'xmom')
                    currSignal = xmomSignalGenerator(tradeCalendar(i),rankingPeriod,type,volScalingType,volScalingDays);  %当前交易信号  横截面动量
                elseif strcmpi(signalType,'ts')
                    currSignal = tsSignalGenerator(tradeCalendar(i) ,tsType ,type) ; %当前交易信号  期限结构
                    %currSignal = tsSignalGenerator(currTradeDate,rankingPeriod,type);  %当前交易信号  期限结构
                elseif strcmpi(signalType,'mix')
                    currSignal = mixSignalGenerator(tradeCalendar(i),rankingPeriod,tsType,firstSortingFactor,type,volScalingDays);  %当前交易信号  混合
                else
                    currSignal = eqwSignalGenerator(tradeCalendar(i),rankingPeriod);  %当前交易信号  等权配置
                end
                
                positionDirection(i,:) = currSignal;
                
                %交易的合约价值
                tradingValue = dynamicEquity(i) * PositionRatio * (1 / marginRatio);
                tradingValue = dynamicEquity(i);
                tradingValuePerCont =  tradingValue/length(currSignal(currSignal~=0));
                
                if volScalingType == 0
                    
                    tempScale = ones(length(currSignal(currSignal~=0)),1);
                    tempScale(1:end) = 1;
                    
                elseif volScalingType == 1
                    
                    %ATR
                    ATRList = [];
                    %%%%%使用ATR进行调整  60日普通波动率
                    for p = 1 : length(commodityDataCell)
                        if abs(currSignal(p))>0
                            currCommdityData  =  commodityDataCell{2,p}.dominant_Adjusted_Data;
                            idx = find(  currCommdityData(:,1)<=tradeCalendar(i),1,'last');
                            temp = currCommdityData(idx -volScalingDays  : idx , :);
                            ATRList = [ATRList;calc_ATR(temp(:,3),temp(:,4),temp(:,5),volScalingDays)/temp(end,5)];
                            %volList = [volList;calc_vol(currCommdityData(idx -60 +1 : idx , end),60/61)];
                        end
                    end
                    volList = ATRList;
                    tradingValuePerContAdjustedbyVol = tradingValue*1./volList/sum(1./volList);
                    tempScale = tradingValuePerContAdjustedbyVol/tradingValuePerCont;
                
                else
                    volList = [];
                    retList = [];
                    %%%%%%使用波动率进行调整  60日普通波动率
                    for p = 1 : length(commodityDataCell)
                        if abs(currSignal(p))>0
                            currCommdityData  =  commodityDataCell{2,p}.dominant_Adjusted_Data;
                            idx = find(  currCommdityData(:,1)<=tradeCalendar(i),1,'last');
                            temp = currCommdityData(idx -volScalingDays +1 : idx , :);
                            %volList = [volList;std(temp(:,end))*sqrt(242)];
                            volList = [volList;calc_vol(currCommdityData(idx -volScalingDays +1 : idx , end),0.94)];
                            retList = [retList ,currCommdityData(idx -volScalingDays +1 : idx , end)];
                        end
                    end
                    %波动率倒数加权
                    tradingValuePerContAdjustedbyVol = tradingValue*1./volList/sum(1./volList);
                    
                    if volScalingType == 3
                        %将波动率调整到同一水平
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.2./volList;
                    elseif volScalingType == 4
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.3./volList;
                    elseif volScalingType == 5
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.4./volList;
                        
                        % 考虑相关系数  相关系数调整
                    elseif volScalingType == 6
                        N = length(volList);
                        [~,ExpCorrC]=cov2corr(cov(retList));
                        avgCorr = (sum(sum(ExpCorrC)) - sum(diag(ExpCorrC)))/(N*(N-1));
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.1./volList*sqrt(N/(1+(N-1)*avgCorr));
                        
                    elseif volScalingType == 7
                        N = length(volList);
                        [~,ExpCorrC]=cov2corr(cov(retList));
                        avgCorr = (sum(sum(ExpCorrC)) - sum(diag(ExpCorrC)))/(N*(N-1));
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.2./volList*sqrt(N/(1+(N-1)*avgCorr));
                        
                    elseif volScalingType == 8
                        
                        PortWts = (currSignal(currSignal~=0))/sum(abs(currSignal));
                        ExpReturn = zeros(size(PortWts));
                        [~,ExpCorrC]=cov2corr(cov(retList));
                        [PortRisk , PortReturn] =portstats( ExpReturn, ExpCorrC , PortWts);
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.1./volList/PortRisk;
                        
                        
                    elseif volScalingType == 9
                        
                        PortWts = (currSignal(currSignal~=0))/sum(abs(currSignal));
                        ExpReturn = zeros(size(PortWts));
                        [~,ExpCorrC]=cov2corr(cov(retList));
                        [PortRisk , PortReturn] =portstats( ExpReturn, ExpCorrC , PortWts);
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.2./volList/PortRisk;
                        
                        
                    elseif volScalingType == 10
                        N = length(volList);
                        covMatrix = cov(retList);
                        weight = fmincon(@(x) riskParityFunc(x,covMatrix),1./volList/sum(1./volList), [],[],ones(1,N) ,1);
                        %tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.2./volList*sqrt(N/(1+(N-1)*avgCorr));
                        tradingValuePerContAdjustedbyVol = tradingValue.*weight;
                        
                    end
                    tempScale = tradingValuePerContAdjustedbyVol/tradingValuePerCont;
                end
                
                %每个合约建仓价格 真实价格 用于计算资金   当天收盘价
                entryPrice =cellfun(@(x) ( x.dominant_Data(x.tradeCalendar == currTradeDate,...
                    5)),commodityDataCell(2,currSignal~=0));
                %每个合约建仓价格 复权价格  用于计算收益
                entryAdjPrice =cellfun(@(x) ( x.dominant_Adjusted_Data(x.tradeCalendar == currTradeDate,...
                    5)),commodityDataCell(2,currSignal~=0));
                
                tradingLots = round( tempScale'.* cellfun(@(x) ( tradingValuePerCont/x.scale/x.dominant_Data(x.tradeCalendar == currTradeDate,...
                    5)),commodityDataCell(2,currSignal~=0)));
                
                %每个合约换手情况
                tradingLotsPerCont = currSignal;
                tradingLotsPerCont(currSignal~=0) =  tradingLotsPerCont(currSignal~=0).*tradingLots;
                tradingLotsTurnover = tradingLotsPerCont - tradingLotsPerContLastTerm;
                
                %滑点成本  按1跳来计算
                slippageCost =sum(cellfun(@(x) (x.scale.*x.minPriceChg),commodityDataCell(2,:)).*abs(tradingLotsTurnover))*slippage;
                
                tradingValueTurnover = sum(cellfun(@(x) ( x.scale*x.dominant_Data(x.tradeCalendar == currTradeDate,...
                    5)),commodityDataCell(2,tradingLotsTurnover~=0)).* abs(tradingLotsTurnover(tradingLotsTurnover~=0)));
                tradingLotsPerContLastTerm = tradingLotsPerCont;
                %当期换手率写入矩阵
                turnoverRatioRecord = [turnoverRatioRecord ; [currTradeDate , tradingValueTurnover/holdingContractValue(i)/2]];
                %静态权益扣手续费
                %staticEquity(i) = staticEquity(i) - tradingValueTurnover*tradingCost;
                temp = tradingLotsPerCont(tradingLotsPerCont~=0);
                currScale = cellfun(@(x) (x.scale),commodityDataCell(2,currSignal~=0));
                currMinPriceChg= cellfun(@(x) (x.minPriceChg),commodityDataCell(2,currSignal~=0));
                currHoldingValue = entryPrice.*tradingLots.*currScale;
                %多头保证金
                longMargin(i) = sum(currHoldingValue(temp>0))*marginRatio;
                %空头保证金
                shortMargin(i) = sum(currHoldingValue(temp<0)).*marginRatio;
                cash(i) = dynamicEquity(i) -  longMargin(i) -  shortMargin(i) - tradingValueTurnover*tradingCost - slippageCost;
            end
            %剩下的资金放回购
            cash(i) = cash(i)*(1 + repoOvernight(i)/360);
            %disp(i)
        end  %loop i
        %profile viewer
        dynamicEquity = dynamicEquity/dynamicEquity(1);
        dynamicEquityMat = [dynamicEquityMat, dynamicEquity];
        tradeRecordMat = [tradeRecordMat, tradeRecord];
        turnoverRatioRecordMat = [turnoverRatioRecordMat;turnoverRatioRecord];
        amountHoldingSum = amountHoldingSum+amountHolding;
    end
    
end

dynamicEquity =  mean(dynamicEquityMat,2);
tradeRecord = tradeRecordMat;
turnoverRatioRecord = turnoverRatioRecordMat;
%净值曲线
dynamicEquity = dynamicEquity/dynamicEquity(1);

plot(dynamicEquity)
