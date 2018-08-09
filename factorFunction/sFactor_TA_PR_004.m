function factorData = sFactor_TA_PR_004()


end

function lines = signal_HHLL(data,para)
% ����
win = para.win;

if size(data,1)>=win
    upB = tsmovavg(data(:,3),'s',win,1); %�Ϲ�
    dnB = tsmovavg(data(:,4),'s',win,1); %�¹�
else
    upB = nan(size(data,1),1);
    dnB = nan(size(data,1),1);
end

lines.Open = data(:,1);
lines.Close = data(:,2);
lines.High = data(:,3);
lines.Low = data(:,4);
lines.upB = upB;
lines.dnB = dnB;

end