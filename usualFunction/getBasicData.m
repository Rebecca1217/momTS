function dataBasic = getBasicData(fut_variety,FPath,dateBasic,PType)
% ��ʱ�������������������


dataBasic = nan(length(dateBasic),length(fut_variety)); % ����һ���վ��󣨽���ģ�
for i_fut = 1:length(fut_variety)
    fut = fut_variety{i_fut};
    % ����Ʒ������
    load([FPath,'\',fut,'.mat'])
    str = ['priceF = futureData.',PType,';'];
    eval(str) %ִ���ı��е�MATLAB����ʽ
    dateF = futureData.Date;
    priceF = getIntersect(priceF,dateBasic,dateF);
    % �Ҿ�������ط����ԡ������price��date��ͬһ��table���棬ֱ������һ��date�����������Ϳ���
    % ��ȡ����Ҫ�������ˣ�����Ҫÿ�����ݶ��ֿ���Ȼ���ٵ�дһ������ȥ��ȡ�����鷳������
    % ������ֻ��һ��date��Ҫ��ȡ������м�����ͬ�����������أ�
    % ��MATLAB�﷨ֻ����������
    % ������table��DT(DT.Var1 > dateST & DT.Var1 <= dateEd, :)����ɸѡ
    
    %Ŀǰ���ڻ�����������Struct�ĸ�ʽ�ڴ洢���൱����ά����ȫ��ɢ�����Բ��õİ취��...
    %�������Լ��ϲ���Table����������������
    
    % ��û��join����������о�join ����data.table��DT1[DT2, on = "Date"]Ҳ����ʵ�֡���
    % ���Եģ�MATLAB��join(A, B)��based on A�� ��B������join��ȥ...
    % ���������join(dateAim, dataRead)������join��Ŀ�������ϣ�Ȼ��roll = TRUE������
    priceF = getFullTS(priceF);
    % �����������ʵ�ֵĹ��ܾ���data.table join��ʱ��roll = TRUE
    dataBasic(:,i_fut) = priceF;
end