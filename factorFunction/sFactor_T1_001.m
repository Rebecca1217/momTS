function factorData = sFactor_T1_001(data,para)
% ===========��������==================
% p(win+1)/p(1)-1
% ȱʧ��������ʱ���ϵĲ�ȫ
% -----------�������---------------
% data.fut_variety;data.FPath;data.Date-����ȱʧֵΪnan���ñ�����Ȩ���ݣ�ԭʼ������
% para.PType;para.win;para.dateST;para.dateED-��Ҫ������
% -----------�������---------------
% factorData:col1-���ڣ��������

dateBasic = data.Date;
fut_variety = data.fut_variety;
FPath = data.FPath;

PType = para.PType;
win = para.win;
dateST = para.dateST;
dateED = para.dateED;

% �������
dataBasic = getBasicData(fut_variety,FPath,dateBasic,PType); %ά�ȣ�ʱ��+Ʒ�֣�����ֻ��Closeһ��

dataBasic_BF = [nan(win,size(dataBasic,2));dataBasic(1:end-win,:)];
factorData = dataBasic./dataBasic_BF-1;
factorData = getFullTS(factorData); %ʱ�����油ȫ����
factorData = getNeedData(factorData,dateBasic,dateST,dateED); %�����������нس���Ҫ������



    
    
