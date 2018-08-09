function TargetPortfolio = get_ContiPortfolio(HoldingPortfolio,totalDate,futMainContPath)
% ���������Ľ����ճֱֲ�Ϊ�����Ľ����ճֲ�
% t�ռ�¼t+1�յ�Ŀ��ֲ�
% �м����ʱ��Ҫע���Ƿ��к�Լ�������£��������������ܼ򵥵������ȥ
if nargin==2
    futMainContPath = 'D:\�ڻ�����2.0\��Ʒ�ڻ�������Լ����';
end
tradeDate = cell2mat(HoldingPortfolio(:,2));
contiDate = totalDate(find(totalDate==tradeDate(1),1):end-1);
if length(tradeDate)==length(contiDate)
    TargetPortfolio = HoldingPortfolio;
    return;
end

TargetPortfolio = cell(length(contiDate),2);
TargetPortfolio(:,2) = num2cell(contiDate);

locs = find(ismember(contiDate,tradeDate));
locsPd = [locs,[locs(2:end);length(contiDate)]-1]; %Ҫ����ֲֵ�����
locsPd(end,2) = length(contiDate);
for l = 1:size(locsPd,1)
    HoldingCont = HoldingPortfolio{l,1}(:,1);
    HoldingFut = regexp(HoldingCont,'\D*(?=\d)','match');
    HoldingFut = reshape([HoldingFut{:}],size(HoldingFut));
    HoldingHands = HoldingPortfolio{l,1}(:,2);
    tmpL = locsPd(l,1):locsPd(l,2);
    for t = tmpL(1):tmpL(end)
        dateI = contiDate(t);
        % ����������Լ����
        load([futMainContPath,'\',num2str(dateI),'.mat'])
        futcont = regexp(maincont(:,1),'\w*(?=\.)','match');
        futcont = reshape([futcont{:}],size(futcont)); %Ʒ��
        maincont = regexp(maincont(:,2),'\w*(?=\.)','match');
        maincont = reshape([maincont{:}],size(maincont)); %����+�·�
        %
        [~,~,li1] = intersect(HoldingFut,futcont,'stable');
        HoldingContI = maincont(li1);        
        TargetPortfolio{t,1} = [HoldingContI,HoldingHands];
    end
end

