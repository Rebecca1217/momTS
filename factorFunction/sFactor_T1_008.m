function factorData = sFactor_T1_008(data,para)
% ===========����������==================
% vol/oi
% ȱʧ��������ʱ���ϵĲ�ȫ
% -----------�������---------------
% data.Vol;data.Interest;data.Date-����ȱʧֵΪnan���ñ�����Ȩ���ݣ�ԭʼ������
% para.dateST;para.dateED-��Ҫ������
% -----------�������---------------
% factorData:col1-���ڣ��������
% inf��������0���棬Ʒ�ֲ���Ծ��ɵ�

dateBasic = data.Date;
fut_variety = data.fut_variety;
FPath = data.FPath;

dateST = para.dateST;
dateED = para.dateED;

% �������
Vol = getBasicData(fut_variety,FPath,dateBasic,'Volume');
Interest = getBasicData(fut_variety,FPath,dateBasic,'Interest');

factorData = Vol./Interest;
factorData(isinf(factorData)) = 0; %����ֲ�Ϊ0����0����inf��û�л���--Ʒ�ּ��Ȳ���Ծ
factorData = getFullTS(factorData); %ʱ�����油ȫ����
factorData = getNeedData(factorData,dateBasic,dateST,dateED); %�����������нس���Ҫ������



    
    
