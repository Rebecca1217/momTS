function [Portfolio,PortfolioTM] = getHoldingHands(HoldingList,HoldingInfo,HoldingInfoTM,PGlobal,Cap,PPath)
% �õ�����Ʒ�ֵĳֲ�Ȩ�غ�����
% ע�⣺HoldingList�����ں�HoldingInfo�����ڲ��Ƕ����
% HoldingList����t�ռ�¼t+1�ĳֲ�Ʒ�ֺͷ���
% HoldingInfo����t�ռ�¼t�ĳֲ�����,HoldingInfo�������������Ҫ��HoldingList����Ķ�һ��
% ����Ҫ��HoldingInfo�ļ�¼��ʽ�����ɺ�HoldingListһ��

% ����
% TestType = PGlobal.TestType;
position = PGlobal.Position; %��λ���÷�ʽ
Capital = Cap.Capital;
futDataPath = PPath.futDataPath;
usualPath = PPath.usualPath;
futMainContPath = PPath.futMainContPath;
% HoldingInfo����
fut_variety = HoldingInfo.fut_variety;
HandsInfo = [HoldingInfo.Hands;HoldingInfoTM.Hands]; %��������
WeightInfo = [HoldingInfo.NomWeight;HoldingInfoTM.NomWeight]; %Ȩ������
infoDate = HandsInfo(:,1); %HoldingInfo��Ӧ������
%
TradeList = HoldingList.TradeList;
% 20180315�޸Ĳ���
empL = cell2mat(cellfun(@(x) isempty(x),TradeList(:,1),'UniformOutput',0));
TradeList(empL,:) = [];
tradeDate = cell2mat(TradeList(:,2)); %TradeList��Ӧ������
% ���ڼ�¼��ʽ���룬infoDateҪȡt+1�յĳֲ�����������tradeList��Ӧ��t�յ���������
[~,~,li1] = intersect(tradeDate,infoDate);
HandsInfo = [tradeDate,HandsInfo(li1+1,2:end)];
WeightInfo = [tradeDate,WeightInfo(li1+1,2:end)];

% ��������
HoldingPortfolio = cell(length(tradeDate),2);
HoldingPortfolio(:,2) = num2cell(tradeDate);
HoldingWeight = cell(length(tradeDate),2);
HoldingWeight(:,2) = num2cell(tradeDate);
if strcmp(position,'flex') %��λ�������-����trendʹ��
    % ���ö��������е������ҵ���Ӧ�������Ϳ�����
    for d = 1:length(tradeDate)
        tradeInfoI = TradeList{d,1}; %d+1�յĳֲ�Ʒ�ֺͷ���
        if isempty(tradeInfoI)
            continue;
        end
        HandsInfoI = HandsInfo(d,2:end); %d+1�ո�Ʒ�ֶ�Ӧ������
        [futI,li0,li1] = intersect(tradeInfoI(:,1),fut_variety);
        handsWithDirect = cell2mat(tradeInfoI(li0,2)).*HandsInfoI(li1)'; %�����������
        portfolioI = [futI,num2cell(handsWithDirect)];
        WeightInfoI = WeightInfo(d,2:end);
        WeightI = [futI,num2cell(WeightInfoI(li1)')];
        %
        HoldingPortfolio{d,1} = portfolioI;
        HoldingWeight{d,1} = WeightI;
    end
    elseif strcmp(position,'full') %���ֻ�����
    % ��Ҫ���ݳֲ�Ȩ��ռ�ȶ��������е���
    % �����Լ����
    load([usualPath,'\cont_multi.mat'])
    for d = 1:length(tradeDate)
        tradeInfoI = TradeList{d,1};
        if isempty(tradeInfoI)
            continue;
        end
        WeightInfoI = WeightInfo(d,2:end); %�ֲ�ռ��
        [futI,li0,li1] = intersect(tradeInfoI(:,1),fut_variety);
        WeightInfoI = WeightInfoI(li1); %���е�Ʒ�ֵĳֲ�Ȩ��
        WeightInfoI = WeightInfoI./sum(WeightInfoI); %Ȩ���ٷ���
        SizeI = Capital*WeightInfoI; %ÿ��Ʒ�ֵĿ�����ֵ
        % ���뵱�յĽ�������
        load([futDataPath,'\',num2str(tradeDate(d)),'.mat'])
        ClCS = futureDataCS.Close; %���̼�
        futCS = futureDataCS.futName; %Ʒ��
        futCS = regexp(futCS,'\D*(?=\d)','match');
        futCS = reshape([futCS{:}],size(futCS));
        [~,~,li2] = intersect(futI,futCS,'stable');
        mainDataI = ClCS(li2);
        [~,~,li2] = intersect(futI,cont_multi(:,1),'stable'); %˳������
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
if tradeDate(end) == infoDate(end-1) %���һ�������������죬��û��
    HoldingPortfolio(end,:) = [];
    HoldingWeight(end,:) = [];
end
% ���׸��гֲֵ����ڿ�ʼ
stL = cellfun(@(x) isempty(x),HoldingPortfolio(:,1),'UniformOutput',0);
stL = cell2mat(stL);
stL = find(stL==0,1,'first');
% HoldingPortfolio�����Ʒ�ִ���Ҫ�����·���Ϣ
HoldingPortfolio = HoldingPortfolio(stL:end,:);
for d = 1:length(HoldingPortfolio)
    dateI = HoldingPortfolio{d,2};
    % ����������Լ����
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

   
    

        
            
        
        
        
        

    
    
    
    



