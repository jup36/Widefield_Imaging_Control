function stimopts_ = organize_rp_trials_pos_neg_stims(stimopts_, stim_type_, outcome_positive_stim_, outcome_negative_stim_)

count_p=0;
count_n=0;
stimopts_.rewarded_stim=zeros(size(stim_type_,1),1);
stimopts_.punished_stim=zeros(size(stim_type_,1),1);
for i=1:size(stim_type_,1)
    if stim_type_(i)==stimopts_.positive_stim
        count_p=count_p+1;
        if outcome_positive_stim_(count_p)==1
            stimopts_.rewarded_stim(i)=1;
        elseif outcome_positive_stim_(count_p)==-1
            stimopts_.punished_stim(i)=1;
        end
    end
    if stim_type_(i)==stimopts_.negative_stim
        count_n=count_n+1;
        if outcome_negative_stim_(count_n)==1
            stimopts_.rewarded_stim(i)=1;
        elseif outcome_negative_stim_(count_n)==-1
            stimopts_.punished_stim(i)=1;
        end
    end
end

end