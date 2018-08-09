function factorData = sFactor_T2_003(data,para)
% ===========�껯����ˮ����==================
% (Spot-Price)/Price*365/N(d)
% ȱʧ��������ʱ���ϵĲ�ȫ
% -----------�������---------------
% data.Date;data.FPath;data.SPath;data.contPath;data.fut_variety
% Path����Լ����·������fut��һ��
% fut_variety:������׺
% para.dateST;para.dateED-��Ҫ������
% -----------�������---------------
% factorData:col1-���ڣ��������
% ������Լ������������ȫ������뵽���յ�����ʱ����Ȼ������

dateBasic = data.Date;
FPath = data.FPath; %�ڻ�����·��
SPath = data.SPath; %�ֻ�����·��
contPath = data.contPath; %��Լ����������·��
fut_variety = data.fut_variety; %

dateST = para.dateST;
dateED = para.dateED;

% ���Ʒ�ִ���
factorData = nan(length(dateBasic),length(fut_variety));
for i_fut = 1:length(fut_variety)
    fut = fut_variety{i_fut};
    % ��������
    load([FPath,'\',fut,'.mat']) %�ڻ�����
    dataF = futureData;
    load([SPath,'\',fut,'.mat']) %�ֻ�����
    dataS = futureData;
    load([contPath,'\',fut,'.mat']) %��Լ������
    ltdInfo = [str2double(dateInfo(:,1)),cell2mat(dateInfo(:,2:3))];
    % ���ܵ����ڶ���
    priceF = getIntersect(dataF.Close,dateBasic,dataF.Date); %����
    contF = getIntersect(str2double(dataF.mainCont),dateBasic,dataF.Date); %��������
    priceS = getIntersect(dataS.Close,dateBasic,dataS.Date); %�ֻ�
    % ��ȫ����
    priceF = getFullTS(priceF);
    contF = getFullTS(contF);
    priceS = getFullTS(priceS);
    % ���Լ���뵽���յ���Ȼ������
    dnumF = getDateNum(contF,dateBasic,ltdInfo);
    % �����껯����ˮ��
    factorData(:,i_fut) = (priceS-priceF)./priceF*365./dnumF;
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




