function factorData = sFactor_T1_003(data,para)
% ==================������������================
% O(t)/C(t-1)-1
% --------------�������-------------------
% data.fut_variety;data.FPath;data.Date;
% para.dateST;para.dateED
% --------------�������------------------
% factorData:col1-���ڣ��������


dateBasic = data.Date;
fut_variety = data.fut_variety;
FPath = data.FPath;

dateST = para.dateST;
dateED = para.dateED;

% �������
Open = getBasicData(fut_variety,FPath,dateBasic,'Open');
Close = getBasicData(fut_variety,FPath,dateBasic,'Close');

Close_BF = [nan(1,size(Close,2));Close(1:end-1,:)];

factorData = Open./Close_BF-1;
factorData = getFullTS(factorData); %ʱ�����油ȫ����
factorData = getNeedData(factorData,dateBasic,dateST,dateED); %�����������нس���Ҫ������