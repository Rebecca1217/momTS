function factorData = sFactor_T1_006(data,para)
% ====================�����в���������==================
% type1:��Ӧ�����е�Type1
% type2:��Ӧ�����е�Type2
% ���в�����/���в�����
% --------------�������-------------------
% data.Price;data.Date;
% para.dateST;para.dateED;para.type;para.win1;para.win2
% win1:���������ʵ�win��win2:���㲨���ʵ�win
% --------------�������------------------
% factorData:col1-���ڣ��������
% --------------�������------------------
% ����inf,������ֵ:ȫΪ�����棬-inf
% ������ֵ������inf:ȫΪ�����棬inf
% �����о�Ϊnan:����ȱʧ��nan
% ���ݲ���ʱ���ϵĲ�ȫ

dateBasic = data.Date;

dateST = para.dateST;
dateED = para.dateED;

paraR.PType = para.PType;
paraR.win1 = para.win1;
paraR.dateST = dateBasic(1);
paraR.dateED = dateBasic(end);
paraR.type = para.type;
paraR.win2 = para.win2;
upV = sFactor_T1_004(data,paraR);
dnV = sFactor_T1_005(data,paraR);

upV(:,1) = []; %ȥ����������
dnV(:,1) = [];

factorData = nan(size(upV));
for d = 1:length(dateBasic) %����
    upVtmp = upV(d,:);
    dnVtmp = dnV(d,:);
    upNan = find(isinf(upVtmp));
    dnNan = find(isinf(dnVtmp));
    onlyUpNan = setdiff(upNan,dnNan); %������Ϊnan
    onlyDnNan = setdiff(dnNan,upNan); %������Ϊnan
    vltmp = upVtmp./dnVtmp;
    vltmp(onlyUpNan) = -inf;
    vltmp(onlyDnNan) = inf;
    factorData(d,:) = vltmp;
end

factorData = getNeedData(factorData,dateBasic,dateST,dateED); %�����������нس���Ҫ������