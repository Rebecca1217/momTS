function dataN = getNeedData(dataOri,dateBasic,dateST,dateED)
% ��������������нس�����ʱ�ε��������
% ���Ҹ�ԭ�������ݼ�������������

stL = find(dateBasic==dateST,1,'first');
edL = find(dateBasic==dateED,1,'first');
dataN = [dateBasic(stL:edL),dataOri(stL:edL,:)];
