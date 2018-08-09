% rankingPeriod ������
% holdingPeriod ������
% volScalingType:0 ��Ȩ 1 ATR������Ȩ  2 �����ʵ�����Ȩ 3 Ŀ�겨����20% 4 Ŀ�겨����30% 5 Ŀ�겨���� 40%
% volScalingDays ���Ʋ����ʵ�ʱ-�䴰��
% smoothingType 0 ��ƽ�� 1 ƽ��
% trdFeeType 0 ���۷� 1 �۷� 2 �۷Ѻ�1������
% enterPriceType 0 ���տ��̼� 1 �������̼� 2 �������̼�
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
enterPriceType = 2;  %��������õ������̳ɽ�

initialEquity = 1000000000;%��ʼ�ʽ�
marginRatio = 0.2;%��֤����
PositionRatio = 0.2; %��λ50%
slippage = 0;
tradingCost = 0.0003; %���׳ɱ�

pathNum = 5;  %·������

gap = holdingPeriod/5;
startIdxList = [0:4]*gap+1;

dynamicEquityMat = [];
tradeRecordMat = [];
turnoverRatioRecordMat = [];
amountHoldingSum = 0;


if ~enterPriceType  %�Դ��տ��̼۳ɽ�
    
    for k = 1 : pathNum
        
        n = startIdxList(k) + 1;
        % profile on
        
        cash = repmat(initialEquity,length(tradeCalendar),1); %�����ʽ�
        dynamicEquity = repmat(initialEquity,length(tradeCalendar),1); %��̬Ȩ��
        longMargin = zeros(length(tradeCalendar),1); %��ͷ��֤��
        shortMargin = zeros(length(tradeCalendar),1); %��ͷ��֤��
        holdingContractValue = zeros(length(tradeCalendar),1); %�ֲֺ�Լ��ֵ
        positionDirection  = zeros(length(tradeCalendar),length(commodityDataCell(1,:))); %�ֲַ���
        positionHolding = zeros(length(tradeCalendar),length(commodityDataCell(1,:))); %�ֲ�����
        tradingLotsPerContLastTerm = zeros(1,length(commodityDataCell)); %��һ�ڵĳֲ�����
        scale = cellfun(@(x) ( x.scale),commodityDataCell(2,:));
        currSignal = zeros(1,length(commodityDataCell)); %��ǰ�ֲַ���
        monthChangeRecord = [];  %���¼�¼
        turnoverRatioRecord = []; %�����ʼ�¼
        
        tradeRecord = []; %��¼ÿһ�ڵı��֣�����summary�з���
        currTermReturn = zeros(1,length(commodityDataCell)); %���ڸ�Ʒ�ֵ�����
        entryPrice = zeros(1,length(commodityDataCell)); %���ڸ�Ʒ�ֵĿ��ּ۸�
        entryAdjPrice = entryPrice;
        
        beginIdx = max(rankingPeriod,holdingPeriod ) + n - 1;
        
        for i = beginIdx : length(tradeCalendar)
            
            currTradeDate = tradeCalendar(i);
            cash(i) =cash(i-1);
            currHoldingContData = commodityDataCell(2,currSignal~=0);
            currPosition = tradingLotsPerContLastTerm(tradingLotsPerContLastTerm~=0);
            positionHolding(i,:) = tradingLotsPerContLastTerm;
            commodityIdx = find(tradingLotsPerContLastTerm);
            
            %������
            if rem(i - beginIdx -1 ,holdingPeriod) == 0 & i < length(tradeCalendar)
                
                %����ӯ�� ������Լ������ ���������ʵ���
                holdingValueChange =  cellfun(@(x) ( x.dominant_Data(x.tradeCalendar == currTradeDate,...
                    2)),currHoldingContData).*(1 - cellfun(@(x) (x.dominant_Adjusted_Data(x.tradeCalendar == currTradeDate,2)/x.dominant_Adjusted_Data(x.tradeCalendar == tradeCalendar(i-1),5)),...
                    currHoldingContData)).*scale(currSignal~=0).*currPosition;
                
                
                if ~isempty(holdingValueChange)
                    
                    longMargin(i) = longMargin(i-1) +   sum(holdingValueChange(currPosition>0));
                    shortMargin(i) = shortMargin(i-1)  +   sum(holdingValueChange(currPosition<0));
                    dynamicEquity(i) =  cash(i)  + longMargin(i) + shortMargin(i); %�ֽ�+��ͷ��֤��+��ͷ��֤��
                    
                end
                
                %��ǰ�ֲּ�ֵ
                holdingContractValue(i) = (longMargin(i) + shortMargin(i))*(1/marginRatio);
                
                
                %���ȼ�¼ƽ�ּ�λ
                closeAdjPrice = cellfun(@(x) ( x.dominant_Adjusted_Data(x.tradeCalendar == tradeCalendar(i),...
                    2)),commodityDataCell(2,currSignal~=0));
                
                if sum(entryAdjPrice) > 0
                    %��һ�ڵ�������
                    currCommodityReturn = closeAdjPrice./entryAdjPrice - 1;%�ǵ���
                    currCommodityReturn = currCommodityReturn.*currSignal(currSignal~=0);%�ǵ���*��λ
                    %���������¼
                    currCommodityReturnCell = [ commodityDataCell(1,currSignal~=0);num2cell(currSignal(currSignal~=0));num2cell(currCommodityReturn);num2cell(tempScale'/length(tempScale))];
                    currCommodityReturnCell = sortrows(currCommodityReturnCell',-3)';
                    
                    if ~volScalingType
                        %��Ȩ��
                        currTermRecord = {currTermStartDate ; currTradeDate;  mean(currCommodityReturn);...
                            currCommodityReturnCell};
                    else
                        %�����ʼ�Ȩ
                        currTermRecord = {currTermStartDate ; currTradeDate; sum((currCommodityReturn).*(tempScale'/length(tempScale))) ;...
                            currCommodityReturnCell};
                    end
                    tradeRecord = [tradeRecord , currTermRecord];
                end
                
                currTermStartDate = currTradeDate;
                
                if strcmpi(signalType,'tsmom')
                    currSignal = tsmomSignalGenerator(tradeCalendar(i-1),rankingPeriod,type);  %��ǰ�����ź�  ʱ�����ж���
                elseif  strcmpi(signalType,'xmom')
                    currSignal = xmomSignalGenerator(tradeCalendar(i-1),rankingPeriod,type,volScalingDays);  %��ǰ�����ź�  ����涯��
                elseif strcmpi(signalType,'ts')
                    currSignal = tsSignalGenerator(tradeCalendar(i-1) ,tsType ,type) ; %��ǰ�����ź�  ���޽ṹ
                    %currSignal = tsSignalGenerator(currTradeDate,rankingPeriod,type);  %��ǰ�����ź�  ���޽ṹ
                elseif strcmpi(signalType,'mix')
                    currSignal = mixSignalGenerator(tradeCalendar(i-1),rankingPeriod,tsType,firstSortingFactor,type,volScalingDays);  %��ǰ�����ź�  ���
                else
                    currSignal = eqwSignalGenerator(tradeCalendar(i-1),rankingPeriod);  %��ǰ�����ź�  ��Ȩ����
                end
                
                positionDirection(i,:) = currSignal;
                
                %���׵ĺ�Լ��ֵ
                tradingValue = dynamicEquity(i) * PositionRatio * (1 / marginRatio);
                tradingValue = dynamicEquity(i);
                tradingValuePerCont =  tradingValue/length(currSignal(currSignal~=0));
                
                if volScalingType == 0
                    
                    tempScale = ones(length(currSignal(currSignal~=0)),1);
                    tempScale(1:end) = 1;
                    
                elseif volScalingType == 1
                    
                    %ATR
                    ATRList = [];
                    %%%%%ʹ��ATR���е���  60����ͨ������
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
                    %%%%%%ʹ�ò����ʽ��е���  60����ͨ������
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
                    %�����ʵ�����Ȩ
                    tradingValuePerContAdjustedbyVol = tradingValue*1./volList/sum(1./volList);
                    
                    if volScalingType == 3
                        %�������ʵ�����ͬһˮƽ
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.2./volList;
                    elseif volScalingType == 4
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.3./volList;
                    elseif volScalingType == 5
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.4./volList;
                        
                        % �������ϵ��  ���ϵ������
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
                
                
                %ÿ����Լ���ּ۸� ��ʵ�۸� ���ڼ����ʽ�   �ڶ��쿪�̼�
                entryPrice =cellfun(@(x) ( x.dominant_Data(x.tradeCalendar == tradeCalendar(i),...
                    2)),commodityDataCell(2,currSignal~=0));
                %ÿ����Լ���ּ۸� ��Ȩ�۸�  ���ڼ�������
                entryAdjPrice =cellfun(@(x) ( x.dominant_Adjusted_Data(x.tradeCalendar == tradeCalendar(i),...
                    2)),commodityDataCell(2,currSignal~=0));
                
                %ÿ����Լ�������� �����ʼ�Ȩ
                %���̼�
                tradingLots = round( tempScale'.* cellfun(@(x) ( tradingValuePerCont/x.scale/x.dominant_Data(x.tradeCalendar == tradeCalendar(i+1),...
                    2)),commodityDataCell(2,currSignal~=0)));
                
                %ÿ����Լ�������
                tradingLotsPerCont = currSignal;
                tradingLotsPerCont(currSignal~=0) =  tradingLotsPerCont(currSignal~=0).*tradingLots;
                tradingLotsTurnover = tradingLotsPerCont - tradingLotsPerContLastTerm;
                
                %����ɱ�  ��1��������
                slippageCost =sum(cellfun(@(x) (x.scale.*x.minPriceChg),commodityDataCell(2,:)).*abs(tradingLotsTurnover))*slippage;
                
                tradingValueTurnover = sum(cellfun(@(x) ( x.scale*x.dominant_Data(x.tradeCalendar == currTradeDate,...
                    5)),commodityDataCell(2,tradingLotsTurnover~=0)).* abs(tradingLotsTurnover(tradingLotsTurnover~=0)));
                tradingLotsPerContLastTerm = tradingLotsPerCont;
                %���ڻ�����д�����
                turnoverRatioRecord = [turnoverRatioRecord ; [currTradeDate , tradingValueTurnover/holdingContractValue(i)/2]];
                %��̬Ȩ���������
                %staticEquity(i) = staticEquity(i) - tradingValueTurnover*tradingCost;
                temp = tradingLotsPerCont(tradingLotsPerCont~=0);
                currScale = cellfun(@(x) (x.scale),commodityDataCell(2,currSignal~=0));
                currMinPriceChg= cellfun(@(x) (x.minPriceChg),commodityDataCell(2,currSignal~=0));
                currHoldingValue = entryPrice.*tradingLots.*currScale;
                %��ͷ��֤��
                longMargin(i) = sum(currHoldingValue(temp>0))*marginRatio;
                %��ͷ��֤��
                shortMargin(i) = sum(currHoldingValue(temp<0)).*marginRatio;
                cash(i) = dynamicEquity(i) -  longMargin(i) -  shortMargin(i) - tradingValueTurnover*tradingCost - slippageCost;
                
                %���������̽���
                holdingValueChange =  cellfun(@(x) ( x.dominant_Data(x.tradeCalendar == currTradeDate,...
                    5) - x.dominant_Data(x.tradeCalendar == currTradeDate,2)),commodityDataCell(2,currSignal~=0)).*scale(currSignal~=0).* tradingLotsPerCont(currSignal~=0);
                %end
                
                currPosition = tradingLotsPerContLastTerm(tradingLotsPerContLastTerm~=0);
                
                if ~isempty(holdingValueChange)
                    
                    longMargin(i) = longMargin(i) +   sum(holdingValueChange(currPosition>0));
                    shortMargin(i) = shortMargin(i)  +   sum(holdingValueChange(currPosition<0));
                    dynamicEquity(i) =  cash(i)  + longMargin(i) + shortMargin(i); %�ֽ�+��ͷ��֤��+��ͷ��֤��
                    
                end
                %��ǰ�ֲּ�ֵ
                holdingContractValue(i) = (longMargin(i) + shortMargin(i))*(1/marginRatio);
                
            else
                %�ǵ�����  ������Լ�����������������ʵ���
                holdingValueChange =  cellfun(@(x) ( x.dominant_Data(x.tradeCalendar == currTradeDate,...
                    5)),currHoldingContData).*(1 - (1./(1 +  cellfun(@(x) (x.dominant_Adjusted_Data(x.tradeCalendar == currTradeDate,end)),...
                    currHoldingContData)))).*scale(currSignal~=0).*currPosition;
                
                if ~isempty(holdingValueChange)
                    
                    longMargin(i) = longMargin(i-1) +   sum(holdingValueChange(currPosition>0)*marginRatio);
                    shortMargin(i) = shortMargin(i-1)  +   sum(holdingValueChange(currPosition<0)*marginRatio);
                    cash(i) = cash(i) + sum(holdingValueChange)*(1 - marginRatio);
                    dynamicEquity(i) =  cash(i)  + longMargin(i) + shortMargin(i); %�ֽ�+��ͷ��֤��+��ͷ��֤��
                    
                    % ��Լ���´���
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
                            holdingValueChange = abs(valueOpen) - abs(valueClose); %��λ�䶯
                            
                            if tempPostion > 0
                                longMargin(i) =  longMargin(i)  + holdingValueChange*marginRatio;
                                cash(i) = cash(i) - holdingValueChange*marginRatio;
                            else
                                shortMargin(i) =  shortMargin(i)  + holdingValueChange*marginRatio;
                                cash(i) = cash(i) - holdingValueChange*marginRatio;
                            end
                            %���㻬�� ��ƽ��1��
                            slippageCost = (abs(lotsClose) + abs(currPosition(j)))*currScale(j)*currMinPriceChg(j)*slippage;
                            cash(i) = cash(i) - (abs(valueClose) + abs(valueOpen)) *tradingCost - slippageCost;
                            monthChangeRecord = [monthChangeRecord; [currTradeDate , commodityIdx(j) , temp(2:5),  ...
                                lotsClose,currPosition(j) ,(abs(valueClose) + abs(valueOpen)) *tradingCost + slippageCost ]];
                            dynamicEquity(i) =  cash(i)  + longMargin(i) + shortMargin(i); %�ֽ�+��ͷ��֤��+��ͷ��֤��
                        end
                    end
                    %��̬Ȩ�棬�˴���Ϊ��Ȩ��
                    %dynamicEquity(i) =  cash(i)  + longMargin(i) + shortMargin(i); %�ֽ�+��ͷ��֤��+��ͷ��֤��
                end
                %��ǰ�ֲּ�ֵ
                holdingContractValue(i) = (longMargin(i) + shortMargin(i))*(1/marginRatio);
            end
            
            %ʣ�µ��ʽ�Żع�
            cash(i) = cash(i)*(1 + repoOvernight(i)/360);
            %disp(i)
        end  %loop i
        %profile viewer
        dynamicEquity = dynamicEquity/dynamicEquity(1);
        dynamicEquityMat = [dynamicEquityMat, dynamicEquity];
        tradeRecordMat = [tradeRecordMat, tradeRecord];
        %disp(n)
    end
    
elseif enterPriceType == 1 %�Դ������̼۳ɽ�
    
    for k = 1 : pathNum
        
        n = startIdxList(k)+1;
        
        cash = repmat(initialEquity,length(tradeCalendar),1); %�����ʽ�
        dynamicEquity = repmat(initialEquity,length(tradeCalendar),1); %��̬Ȩ��
        longMargin = zeros(length(tradeCalendar),1); %��ͷ��֤��
        shortMargin = zeros(length(tradeCalendar),1); %��ͷ��֤��
        holdingContractValue = zeros(length(tradeCalendar),1); %�ֲֺ�Լ��ֵ
        positionDirection  = zeros(length(tradeCalendar),length(commodityDataCell(1,:))); %�ֲַ���
        positionHolding = zeros(length(tradeCalendar),length(commodityDataCell(1,:))); %�ֲ�����
        tradingLotsPerContLastTerm = zeros(1,length(commodityDataCell)); %��һ�ڵĳֲ�����
        scale = cellfun(@(x) ( x.scale),commodityDataCell(2,:));
        currSignal = zeros(1,length(commodityDataCell)); %��ǰ�ֲַ���
        monthChangeRecord = [];  %���¼�¼
        turnoverRatioRecord = []; %�����ʼ�¼
        
        tradeRecord = []; %��¼ÿһ�ڵı��֣�����summary�з���
        currTermReturn = zeros(1,length(commodityDataCell)); %���ڸ�Ʒ�ֵ�����
        entryPrice = zeros(1,length(commodityDataCell)); %���ڸ�Ʒ�ֵĿ��ּ۸�
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
                dynamicEquity(i) =  cash(i)  + longMargin(i) + shortMargin(i); %�ֽ�+��ͷ��֤��+��ͷ��֤��
                
                % ��Լ���´���
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
                        holdingValueChange = abs(valueOpen) - abs(valueClose); %��λ�䶯
                        
                        if tempPostion > 0
                            longMargin(i) =  longMargin(i)  + holdingValueChange*marginRatio;
                            cash(i) = cash(i) - holdingValueChange*marginRatio;
                        else
                            shortMargin(i) =  shortMargin(i)  + holdingValueChange*marginRatio;
                            cash(i) = cash(i) - holdingValueChange*marginRatio;
                        end
                        %���㻬�� ��ƽ��1��
                        slippageCost = (abs(lotsClose) + abs(currPosition(j)))*currScale(j)*currMinPriceChg(j)*slippage;
                        cash(i) = cash(i) - (abs(valueClose) + abs(valueOpen)) *tradingCost - slippageCost;
                        monthChangeRecord = [monthChangeRecord; [currTradeDate , commodityIdx(j) , temp(2:5),  ...
                            lotsClose,currPosition(j) ,(abs(valueClose) + abs(valueOpen)) *tradingCost + slippageCost ]];
                        dynamicEquity(i) =  cash(i)  + longMargin(i) + shortMargin(i); %�ֽ�+��ͷ��֤��+��ͷ��֤��
                    end
                end
            end
            
            %��ǰ�ֲּ�ֵ
            holdingContractValue(i) = (longMargin(i) + shortMargin(i))*(1/marginRatio);
            
            %������
            if rem(i - beginIdx ,holdingPeriod) == 0 & i < length(tradeCalendar)
                
                %���ȼ�¼ƽ�ּ�λ
                closeAdjPrice = cellfun(@(x) ( x.dominant_Adjusted_Data(x.tradeCalendar == currTradeDate,...
                    5)),commodityDataCell(2,currSignal~=0));
                if sum(entryAdjPrice) > 0
                    %��һ�ڵ�������
                    currCommodityReturn = closeAdjPrice./entryAdjPrice - 1;%�ǵ���
                    currCommodityReturn = currCommodityReturn.*currSignal(currSignal~=0);%�ǵ���*��λ
                    
                    %���������¼
                    currCommodityReturnCell = [ commodityDataCell(1,currSignal~=0);num2cell(currSignal(currSignal~=0));num2cell(currCommodityReturn);num2cell(tempScale'/sum(tempScale))];
                    currCommodityReturnCell = sortrows(currCommodityReturnCell',-3)';
                    
                    currTermRecord = {currTermStartDate ; currTradeDate; sum((1+currCommodityReturn).*tempScale')/sum(tempScale)-1 ;...
                        currCommodityReturnCell};
                    tradeRecord = [tradeRecord , currTermRecord];
                    
                end
                
                currTermStartDate = currTradeDate;
                
                if strcmpi(signalType,'tsmom')
                    currSignal = tsmomSignalGenerator(tradeCalendar(i-1),rankingPeriod,type);  %��ǰ�����ź�  ʱ�����ж���
                elseif  strcmpi(signalType,'xmom')
                    currSignal = xmomSignalGenerator(tradeCalendar(i-1),rankingPeriod,type,volScalingType,volScalingDays);  %��ǰ�����ź�  ����涯��
                elseif strcmpi(signalType,'ts')
                    currSignal = tsSignalGenerator(tradeCalendar(i-1) ,tsType ,type) ; %��ǰ�����ź�  ���޽ṹ
                    %currSignal = tsSignalGenerator(currTradeDate,rankingPeriod,type);  %��ǰ�����ź�  ���޽ṹ
                elseif strcmpi(signalType,'mix')
                    currSignal = mixSignalGenerator(tradeCalendar(i-1),rankingPeriod,tsType,firstSortingFactor,type,volScalingDays);  %��ǰ�����ź�  ���
                else
                    currSignal = eqwSignalGenerator(tradeCalendar(i-1),rankingPeriod);  %��ǰ�����ź�  ��Ȩ����
                end
                
                positionDirection(i,:) = currSignal;
                
                %���׵ĺ�Լ��ֵ
                tradingValue = dynamicEquity(i) * PositionRatio * (1 / marginRatio);
                tradingValue = dynamicEquity(i);
                tradingValuePerCont =  tradingValue/length(currSignal(currSignal~=0));
                
                if volScalingType == 0
                    
                    tempScale = ones(length(currSignal(currSignal~=0)),1);
                    tempScale(1:end) = 1;
                    
                elseif volScalingType == 1
                    
                    %ATR
                    ATRList = [];
                    %%%%%ʹ��ATR���е���  60����ͨ������
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
                    %%%%%%ʹ�ò����ʽ��е���  60����ͨ������
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
                    %�����ʵ�����Ȩ
                    tradingValuePerContAdjustedbyVol = tradingValue*1./volList/sum(1./volList);
                    
                    if volScalingType == 3
                        %�������ʵ�����ͬһˮƽ
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.2./volList;
                    elseif volScalingType == 4
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.3./volList;
                    elseif volScalingType == 5
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.4./volList;
                        
                        % �������ϵ��  ���ϵ������
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
                
                
                %ÿ����Լ���ּ۸� ��ʵ�۸� ���ڼ����ʽ�   �������̼�
                entryPrice =cellfun(@(x) ( x.dominant_Data(x.tradeCalendar == currTradeDate,...
                    5)),commodityDataCell(2,currSignal~=0));
                %ÿ����Լ���ּ۸� ��Ȩ�۸�  ���ڼ�������
                entryAdjPrice =cellfun(@(x) ( x.dominant_Adjusted_Data(x.tradeCalendar == currTradeDate,...
                    5)),commodityDataCell(2,currSignal~=0));
                
                tradingLots = round( tempScale'.* cellfun(@(x) ( tradingValuePerCont/x.scale/x.dominant_Data(x.tradeCalendar == currTradeDate,...
                    5)),commodityDataCell(2,currSignal~=0)));
                
                
                %ÿ����Լ�������
                tradingLotsPerCont = currSignal;
                tradingLotsPerCont(currSignal~=0) =  tradingLotsPerCont(currSignal~=0).*tradingLots;
                tradingLotsTurnover = tradingLotsPerCont - tradingLotsPerContLastTerm;
                
                %����ɱ�  ��1��������
                slippageCost =sum(cellfun(@(x) (x.scale.*x.minPriceChg),commodityDataCell(2,:)).*abs(tradingLotsTurnover))*slippage;
                
                tradingValueTurnover = sum(cellfun(@(x) ( x.scale*x.dominant_Data(x.tradeCalendar == currTradeDate,...
                    5)),commodityDataCell(2,tradingLotsTurnover~=0)).* abs(tradingLotsTurnover(tradingLotsTurnover~=0)));
                tradingLotsPerContLastTerm = tradingLotsPerCont;
                %���ڻ�����д�����
                turnoverRatioRecord = [turnoverRatioRecord ; [currTradeDate , tradingValueTurnover/holdingContractValue(i)/2]];
                %��̬Ȩ���������
                %staticEquity(i) = staticEquity(i) - tradingValueTurnover*tradingCost;
                temp = tradingLotsPerCont(tradingLotsPerCont~=0);
                currScale = cellfun(@(x) (x.scale),commodityDataCell(2,currSignal~=0));
                currMinPriceChg= cellfun(@(x) (x.minPriceChg),commodityDataCell(2,currSignal~=0));
                currHoldingValue = entryPrice.*tradingLots.*currScale;
                %��ͷ��֤��
                longMargin(i) = sum(currHoldingValue(temp>0))*marginRatio;
                %��ͷ��֤��
                shortMargin(i) = sum(currHoldingValue(temp<0)).*marginRatio;
                cash(i) = dynamicEquity(i) -  longMargin(i) -  shortMargin(i) - tradingValueTurnover*tradingCost - slippageCost;
            end
            %ʣ�µ��ʽ�Żع�
            cash(i) = cash(i)*(1 + repoOvernight(i)/360);
            %disp(i)
        end  %loop i
        %profile viewer
        dynamicEquity = dynamicEquity/dynamicEquity(1);
        dynamicEquityMat = [dynamicEquityMat, dynamicEquity];
        tradeRecordMat = [tradeRecordMat, tradeRecord];
    end
    
else %�Ե������̼۳ɽ�
    
    for k = 1 : pathNum
        
        n = startIdxList(k)+1;
        
        cash = repmat(initialEquity,length(tradeCalendar),1); %�����ʽ�
        dynamicEquity = repmat(initialEquity,length(tradeCalendar),1); %��̬Ȩ��
        longMargin = zeros(length(tradeCalendar),1); %��ͷ��֤��
        shortMargin = zeros(length(tradeCalendar),1); %��ͷ��֤��
        holdingContractValue = zeros(length(tradeCalendar),1); %�ֲֺ�Լ��ֵ
        positionDirection  = zeros(length(tradeCalendar),length(commodityDataCell(1,:))); %�ֲַ���
        positionHolding = zeros(length(tradeCalendar),length(commodityDataCell(1,:))); %�ֲ�����
        amountHolding = zeros(length(tradeCalendar),length(commodityDataCell(1,:)));    %�ֲ����
        
        tradingLotsPerContLastTerm = zeros(1,length(commodityDataCell)); %��һ�ڵĳֲ�����
        scale = cellfun(@(x) ( x.scale),commodityDataCell(2,:));
        currSignal = zeros(1,length(commodityDataCell)); %��ǰ�ֲַ���
        monthChangeRecord = [];  %���¼�¼
        turnoverRatioRecord = []; %�����ʼ�¼
        
        tradeRecord = []; %��¼ÿһ�ڵı��֣�����summary�з���
        currTermReturn = zeros(1,length(commodityDataCell)); %���ڸ�Ʒ�ֵ�����
        entryPrice = zeros(1,length(commodityDataCell)); %���ڸ�Ʒ�ֵĿ��ּ۸�
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
                cash(i) = cash(i) + sum(holdingValueChange)*(1 - marginRatio); % ����׷���˱�֤�𣬿����ʽ���Ӧ�ü��٣�
                %
                % margin cash equity���ߵ�ת����ϵ�������ģ�
                % �����Ӧ����cash��Ǯ����֤����cashӦ�ü��٣�Ȩ��Ӧ�����Ӱ� ��鲻̫��⡣����
                dynamicEquity(i) =  cash(i)  + longMargin(i) + shortMargin(i); %�ֽ�+��ͷ��֤��+��ͷ��֤��
                
                % ��Լ���´���
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
                        holdingValueChange = abs(valueOpen) - abs(valueClose); %��λ�䶯
                        
                        if tempPostion > 0
                            longMargin(i) =  longMargin(i)  + holdingValueChange*marginRatio;
                            cash(i) = cash(i) - holdingValueChange*marginRatio;
                        else
                            shortMargin(i) =  shortMargin(i)  + holdingValueChange*marginRatio;
                            cash(i) = cash(i) - holdingValueChange*marginRatio;
                        end
                        %���㻬�� ��ƽ��1��
                        slippageCost = (abs(lotsClose) + abs(currPosition(j)))*currScale(j)*currMinPriceChg(j)*slippage;
                        cash(i) = cash(i) - (abs(valueClose) + abs(valueOpen)) *tradingCost - slippageCost;
                        monthChangeRecord = [monthChangeRecord; [currTradeDate , commodityIdx(j) , temp(2:5),  ...
                            lotsClose,currPosition(j) ,(abs(valueClose) + abs(valueOpen)) *tradingCost + slippageCost ]];
                        dynamicEquity(i) =  cash(i)  + longMargin(i) + shortMargin(i); %�ֽ�+��ͷ��֤��+��ͷ��֤��
                    end
                end
            end
            
            %��ǰ�ֲּ�ֵ
            holdingContractValue(i) = (longMargin(i) + shortMargin(i))*(1/marginRatio);
            
            %������
            %%%%%%%%%%%%%�����ǲ��Եĺ��Ĳ��֣��ڻ����յ�ʱ�򷢳������źţ�
            if rem(i - beginIdx ,holdingPeriod) == 0 && i < length(tradeCalendar)
                
                %���ȼ�¼ƽ�ּ�λ
                closeAdjPrice = cellfun(@(x) ( x.dominant_Adjusted_Data(x.tradeCalendar == currTradeDate,...
                    5)),commodityDataCell(2,currSignal~=0));
                if sum(entryAdjPrice) > 0
                    %��һ�ڵ�������
                    currCommodityReturn = closeAdjPrice./entryAdjPrice - 1;%�ǵ���
                    currCommodityReturn = currCommodityReturn.*currSignal(currSignal~=0);%�ǵ���*��λ
                    
                    %���������¼
                    currCommodityReturnCell = [ commodityDataCell(1,currSignal~=0);num2cell(currSignal(currSignal~=0));num2cell(currCommodityReturn);num2cell(tempScale'/sum(tempScale))];
                    currCommodityReturnCell = sortrows(currCommodityReturnCell',-3)';
                    
                    currTermRecord = {currTermStartDate ; currTradeDate; sum((1+currCommodityReturn).*tempScale')/sum(tempScale)-1 ;...
                        currCommodityReturnCell};
                    tradeRecord = [tradeRecord , currTermRecord];
                    
                end
                
                currTermStartDate = currTradeDate;
                
                if strcmpi(signalType,'tsmom')
                    currSignal = tsmomSignalGenerator(tradeCalendar(i),rankingPeriod,type);  %��ǰ�����ź�  ʱ�����ж���
                elseif  strcmpi(signalType,'xmom')
                    currSignal = xmomSignalGenerator(tradeCalendar(i),rankingPeriod,type,volScalingType,volScalingDays);  %��ǰ�����ź�  ����涯��
                elseif strcmpi(signalType,'ts')
                    currSignal = tsSignalGenerator(tradeCalendar(i) ,tsType ,type) ; %��ǰ�����ź�  ���޽ṹ
                    %currSignal = tsSignalGenerator(currTradeDate,rankingPeriod,type);  %��ǰ�����ź�  ���޽ṹ
                elseif strcmpi(signalType,'mix')
                    currSignal = mixSignalGenerator(tradeCalendar(i),rankingPeriod,tsType,firstSortingFactor,type,volScalingDays);  %��ǰ�����ź�  ���
                else
                    currSignal = eqwSignalGenerator(tradeCalendar(i),rankingPeriod);  %��ǰ�����ź�  ��Ȩ����
                end
                
                positionDirection(i,:) = currSignal;
                
                %���׵ĺ�Լ��ֵ
                tradingValue = dynamicEquity(i) * PositionRatio * (1 / marginRatio);
                tradingValue = dynamicEquity(i);
                tradingValuePerCont =  tradingValue/length(currSignal(currSignal~=0));
                
                if volScalingType == 0
                    
                    tempScale = ones(length(currSignal(currSignal~=0)),1);
                    tempScale(1:end) = 1;
                    
                elseif volScalingType == 1
                    
                    %ATR
                    ATRList = [];
                    %%%%%ʹ��ATR���е���  60����ͨ������
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
                    %%%%%%ʹ�ò����ʽ��е���  60����ͨ������
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
                    %�����ʵ�����Ȩ
                    tradingValuePerContAdjustedbyVol = tradingValue*1./volList/sum(1./volList);
                    
                    if volScalingType == 3
                        %�������ʵ�����ͬһˮƽ
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.2./volList;
                    elseif volScalingType == 4
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.3./volList;
                    elseif volScalingType == 5
                        tradingValuePerContAdjustedbyVol = tradingValuePerCont*0.4./volList;
                        
                        % �������ϵ��  ���ϵ������
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
                
                %ÿ����Լ���ּ۸� ��ʵ�۸� ���ڼ����ʽ�   �������̼�
                entryPrice =cellfun(@(x) ( x.dominant_Data(x.tradeCalendar == currTradeDate,...
                    5)),commodityDataCell(2,currSignal~=0));
                %ÿ����Լ���ּ۸� ��Ȩ�۸�  ���ڼ�������
                entryAdjPrice =cellfun(@(x) ( x.dominant_Adjusted_Data(x.tradeCalendar == currTradeDate,...
                    5)),commodityDataCell(2,currSignal~=0));
                
                tradingLots = round( tempScale'.* cellfun(@(x) ( tradingValuePerCont/x.scale/x.dominant_Data(x.tradeCalendar == currTradeDate,...
                    5)),commodityDataCell(2,currSignal~=0)));
                
                %ÿ����Լ�������
                tradingLotsPerCont = currSignal;
                tradingLotsPerCont(currSignal~=0) =  tradingLotsPerCont(currSignal~=0).*tradingLots;
                tradingLotsTurnover = tradingLotsPerCont - tradingLotsPerContLastTerm;
                
                %����ɱ�  ��1��������
                slippageCost =sum(cellfun(@(x) (x.scale.*x.minPriceChg),commodityDataCell(2,:)).*abs(tradingLotsTurnover))*slippage;
                
                tradingValueTurnover = sum(cellfun(@(x) ( x.scale*x.dominant_Data(x.tradeCalendar == currTradeDate,...
                    5)),commodityDataCell(2,tradingLotsTurnover~=0)).* abs(tradingLotsTurnover(tradingLotsTurnover~=0)));
                tradingLotsPerContLastTerm = tradingLotsPerCont;
                %���ڻ�����д�����
                turnoverRatioRecord = [turnoverRatioRecord ; [currTradeDate , tradingValueTurnover/holdingContractValue(i)/2]];
                %��̬Ȩ���������
                %staticEquity(i) = staticEquity(i) - tradingValueTurnover*tradingCost;
                temp = tradingLotsPerCont(tradingLotsPerCont~=0);
                currScale = cellfun(@(x) (x.scale),commodityDataCell(2,currSignal~=0));
                currMinPriceChg= cellfun(@(x) (x.minPriceChg),commodityDataCell(2,currSignal~=0));
                currHoldingValue = entryPrice.*tradingLots.*currScale;
                %��ͷ��֤��
                longMargin(i) = sum(currHoldingValue(temp>0))*marginRatio;
                %��ͷ��֤��
                shortMargin(i) = sum(currHoldingValue(temp<0)).*marginRatio;
                cash(i) = dynamicEquity(i) -  longMargin(i) -  shortMargin(i) - tradingValueTurnover*tradingCost - slippageCost;
            end
            %ʣ�µ��ʽ�Żع�
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
%��ֵ����
dynamicEquity = dynamicEquity/dynamicEquity(1);

plot(dynamicEquity)
