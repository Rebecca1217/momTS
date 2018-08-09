function factorData = sFactor_T1_009(data,para)
% ===========�����ʽ�����==================
% sum(Price*OI*��Լ����*��֤�����)
% price�����̼ۻ��߽����
% ȱʧ��������ʱ���ϵĲ�ȫ
% -----------�������---------------
% data.FPath;data.fut_variety;data.punitPath;data.depPath;data.Date
% punit,dep·�����嵽mat�ļ�;FPath��fut����һ��
% para.dateST;para.dateED;para.priceType-��Ҫ������
% priceType:Close��Settle
% -----------�������---------------
% factorData:col1-���ڣ��������
% -----------�������---------------
% �ȶԵ����·ݺ�Լ���в�ȫ��Ȼ��ϳ��ܵĳ����ʽ��ٴβ�ȫ

dateBasic = data.Date;
fut_variety = data.fut_variety;
FPath = data.FPath;
depPath = data.depPath;
punitPath = data.punitPath;

dateST = para.dateST;
dateED = para.dateED;
pType = para.PType;

% ���Ʒ�ִ���-�����Լ
factorData = zeros(length(dateBasic),length(fut_variety));
for i_fut = 1:length(fut_variety)
    fut = fut_variety{i_fut};
    % �����Լ�����ͱ�֤�����
    load(depPath,fut)
    str = ['DepositInfo = ',fut,'.DepositInfo;'];
    eval(str)
    load(punitPath,fut)
    str = ['PunitInfo = ',fut,'.PunitInfo;'];
    eval(str)
    % ���ܵ����ڶ���
    DepositInfo = getIntersect(DepositInfo(:,2),dateBasic,DepositInfo(:,1));
    PunitInfo = getIntersect(PunitInfo(:,2),dateBasic,PunitInfo(:,1));
    DepositInfo = getFullTS(DepositInfo);
    PunitInfo = getFullTS(PunitInfo);
    
    futFiles = dir([FPath,'\',fut]);
    futFiles = {futFiles(3:end).name};
    money = nan(length(dateBasic),1);
    for i = 1:length(futFiles) %�����Լ
        load([FPath,'\',fut,'\',futFiles{i}])
        str = ['price = futureData.',pType,';'];
        eval(str) %�۸�
        Interest = futureData.Interest; %�ֲ�
        date = futureData.Date; %����
        % ���ܵ����ڶ���
        price = getIntersect(price,dateBasic,date);
        price = getFullTS(price);
        Interest = getIntersect(Interest,dateBasic,date);
        Interest = getFullTS(Interest);
        % ����ú�Լ�ĳ����ʽ�
        tmp = price.*Interest.*PunitInfo.*DepositInfo;
        nanL = find(and(isnan(money),isnan(tmp))); %�ҳ�����ȱʧ����
        money = nansum([money,tmp],2); %��Ϊ���money��tmp��Ϊnan��ʹ��nansum֮�󣬺�Ϊ0
        money(nanL) = nan;
        money = getFullTS(money); %���ݲ�ȫ
    end
    factorData(:,i_fut) = money;
end
        
factorData = getFullTS(factorData); %ʱ�����油ȫ����
factorData = getNeedData(factorData,dateBasic,dateST,dateED); %�����������нس���Ҫ������
end

   
        
function dataAim = getIntersect(data,dateAim,dateD)
% ��������dateAim����

[~,li0,li1] = intersect(dateAim,dateD);
dataAim = nan(length(dateAim),1);
dataAim(li0) = data(li1);
end




    
    
