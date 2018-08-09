function HoldingList = getHoldings(factorDate,PFactor,TradePara,PGlobal)
% ȷ��ÿ�ڳֲֵ�Ʒ�ֺͷ���

% �������
TestType = PGlobal.TestType;
IndustryChoice = PGlobal.IndustryChoice;
% ·��
FactorPath = PFactor.FactorPath;
futLiquidPath = TradePara.futLiquidPath;
futSectorPath = TradePara.futSectorPath;
% ����ð���Ӧ��Ʒ��
load(futSectorPath,IndustryChoice)
str = ['SectorInfo = ',IndustryChoice,';'];
eval(str)
TradeList = cell(length(factorDate),2); %��¼����Ʒ�ֺͽ��׷���
TradeList(:,2) = num2cell(factorDate);
if strcmp(TestType,'hedge')
    GroupList = cell(length(factorDate),2); %��¼�������
    GroupList(:,2) = num2cell(factorDate);
end
for td = 1:length(factorDate) %���������,ע��factorDate�м�¼���ǵ����յ�ǰһ��
    dateI = factorDate(td);   
    load([FactorPath,'\',num2str(dateI),'.mat']) % ������������
    % Ʒ��ɸѡ
    factorData(isnan(cell2mat(factorData(:,2))),:) = []; %�޳�����ֵȱʧ��Ʒ��
    if isempty(factorData) %��������Ʒ�ֵ�����ֵ��ȱʧ
        continue;
    end
    [~,~,li0] = intersect(SectorInfo,factorData(:,1)); %�޳��Ǹð���ڵ�Ʒ��
    factorData = factorData(li0,:);
    if isempty(factorData) %û�иð���ڵ�Ʒ��
        continue;
    end
    load([futLiquidPath,'\',num2str(dateI),'.mat']) %�޳������Բ��Ʒ��
    [~,~,li0] = intersect(liquidityInfo,factorData(:,1));
    factorData = factorData(li0,:);
    if isempty(factorData) %û������������Ҫ���Ʒ��
        continue;
    end
    if strcmp(TestType,'hedge') %����������ʽ�ز�
        GroupNum = PFactor.GroupNum;
        if size(factorData,1)<GroupNum %�����ѡ��Ʒ�������ڷ�����
            continue;
        end
    end
    % ȷ������Ʒ�ֲֳ�
    futFactor = factorData(:,1);
    futData = cell2mat(factorData(:,2));
    if strcmp(TestType,'trend') %������
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
    elseif strcmp(TestType,'hedge') %������
        GroupNum = PFactor.GroupNum; %������
        LongDirect = PFactor.LongDirect;
        num = length(futData);
        futnum = floor(num/GroupNum); %������ڻ�����
        remnum = rem(num,GroupNum); %����
        med = num/2; %��λ������λ��
        if med==floor(med)
            med = med+1;
        else
            med = med+0.5;
        end
        [~,locs] = sort(futData); %��������
        futData = futData(locs);
        futFactor = futFactor(locs);
        if remnum~=0 %������
            if rem(remnum,2)==0 %ż��
                dltLocs = med-remnum/2+1:med+remnum/2;
            else %ż��
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
        if strcmp(LongDirect,'max') %�������һ��
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
    
        
            
            
        
        
        
        
        
        


