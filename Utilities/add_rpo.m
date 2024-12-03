function rpo = add_rpo(prob_arr, total_trials)

rpo = [];
rpo = [rpo;
    ones(floor(prob_arr(1)*total_trials),1)]; %reward
rpo = [rpo;
    -1*ones(floor(prob_arr(3)*total_trials),1)]; %punishment
rpo = [rpo;
    zeros(total_trials-length(rpo),1)]; %omission
%randomize
rpo = rpo(randperm(size(rpo,1),size(rpo,1)));

end