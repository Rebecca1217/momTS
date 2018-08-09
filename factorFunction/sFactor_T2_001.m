function factorData = sFactor_T2_001(data,para)
% ===========չ������������==================
% (lnC(t,n)-lnC(t,f))/D(t,f)-D(t,n)*365
% ȱʧ��������ʱ���ϵĲ�ȫ
% -----------�������---------------
% data.Date;data.ZPath;data.CPath;data.contPath;data.fut_variety
% Path����Լ����·������fut��һ��
% fut_variety:������׺
% para.dateST;para.dateED-��Ҫ������
% -----------�������---------------
% factorData:col1-���ڣ��������
% ������Լ������������ȫ������뵽���յ�����ʱ����Ȼ������
% -----------����˵��--------------
% δ���쳣ֵ���д��������Լ�б�����������ۿ����Ǻ�Լ�����ɵ�
% ���������Լû�б�������������ۣ���ĳ����Լ�����˴�Ĳ��������������Ŀǰû�д���
% ����֮���Ƿ�Ҫ���쳣ֵ������Ҫ����һ��

dateBasic = data.Date;
ZPath = data.ZPath; %������Լ·��
CPath = data.CPath; %��������Լ·��
contPath = data.contPath; %��Լ����������·��
fut_variety = data.fut_variety;

dateST = para.dateST;
dateED = para.dateED;

% ���Ʒ�ִ���
factorData = nan(length(dateBasic),length(fut_variety));
for i_fut = 1:length(fut_variety)
    fut = fut_variety{i_fut};
    % ��������
    load([ZPath,'\',fut,'.mat']) %����    
    dataZ = futureData;
    load([CPath,'\',fut,'.mat']) %������
    dataC = futureData;
    load([contPath,'\',fut,'.mat']) %��Լ����������
    ltdInfo = [str2double(dateInfo(:,1)),cell2mat(dateInfo(:,2:3))];
    % ���ܵ����ڶ���
    priceZ = getIntersect(dataZ.Close,dateBasic,dataZ.Date); %����
    contZ = getIntersect(str2double(dataZ.mainCont),dateBasic,dataZ.Date); %��������
    priceC = getIntersect(dataC.Close,dateBasic,dataC.Date); %������
    contC = getIntersect(str2double(dataC.secondCont),dateBasic,dataC.Date); %����������
    % ��ȫ����
    priceZ = getFullTS(priceZ);
    contZ = getFullTS(contZ);
    priceC = getFullTS(priceC);
    contC = getFullTS(contC);
    % �������Լ���뵽���յ���Ȼ������
    dnumZ = getDateNum(contZ,dateBasic,ltdInfo);
    dnumC = getDateNum(contC,dateBasic,ltdInfo);
    % ����չ��������
    factorData(:,i_fut) = (log(priceZ)-log(priceC))./(dnumC-dnumZ)*365;
end
    
factorData = getFullTS(factorData); %ʱ�����油ȫ����
factorData = getNeedData(factorData,dateBasic,dateST,dateED); %�����������нس���Ҫ������

end
         


function dnum = getDateNum(cont,dateBasic,ltdInfo)
% �����Լ���뵽���յ���Ȼ������

info = nan(length(dateBasic),3);
info(:,1:2) = [cont,dateBasic];
contUni = unique(cont);
for c = 1:length(contUni)
    info(cont==contUni(c),3) = ltdInfo(ltdInfo(:,1)==contUni(c),3);
end
dnum = nan(length(dateBasic),1);
stL = find(~isnan(info(:,1)),1,'first');
dnum(stL:end) = datenum(num2str(info(stL:end,3)),'yyyymmdd')-datenum(num2str(info(stL:end,2)),'yyyymmdd');

end

    
    
