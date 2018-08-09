function factorData = sFactor_T1_002(data,para)
% =============�۸����λ������==================
% (C-LL)/(HH-LL)
% HH=max(H[1:win])
% --------------�������-------------------
% data.fut_variety;data.FPath;data.Date
% para.win;para.dateST;para.dateED
% --------------�������------------------
% factorData:col1-���ڣ��������

dateBasic = data.Date;
fut_variety = data.fut_variety;
FPath = data.FPath;

win = para.win;
dateST = para.dateST;
dateED = para.dateED;

% �������
High = getBasicData(fut_variety,FPath,dateBasic,'High');
Low = getBasicData(fut_variety,FPath,dateBasic,'Low');
Close = getBasicData(fut_variety,FPath,dateBasic,'Close');


HH = hhigh(High,win,1);
HH(1:win-1,:) = nan;
LL = llow(Low,win,1);
LL(1:win-1,:) = nan;

factorData = (Close-LL)./(HH-LL);
factorData = getFullTS(factorData); %ʱ�����油ȫ����
factorData = getNeedData(factorData,dateBasic,dateST,dateED); %�����������нس���Ҫ������
