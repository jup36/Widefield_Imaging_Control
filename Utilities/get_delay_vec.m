function delay_vec = get_delay_vec(s, trial_Idx)
%Get the delay_vec that corresponds to all delays/durations (organized in a sequential manner) within the
% trial. 
if s.rewarded_stim(trial_Idx)
    delay_vec=[s.stim_delay(trial_Idx), s.stim_duration, ...
        s.outcome_delay(trial_Idx), s.reward_duration, ...
        s.reward_duration_padding, s.post_outcome_delay, ...
        s.post_outcome_delay_padding(trial_Idx), s.tail_camera_frame_padding];
elseif s.punished_stim(trial_Idx)
    delay_vec=[s.stim_delay(trial_Idx), s.stim_duration, ...
        s.outcome_delay(trial_Idx), s.air_puff_duration, ...
        s.air_puff_duration_padding, s.post_outcome_delay, ...
        s.post_outcome_delay_padding(trial_Idx), s.tail_camera_frame_padding];
else
    delay_vec=[s.stim_delay(trial_Idx), s.stim_duration, ...
        s.outcome_delay(trial_Idx), s.nothing_duration, ...
        s.nothing_duration_padding, s.post_outcome_delay, ...
        s.post_outcome_delay_padding(trial_Idx), s.tail_camera_frame_padding];
end

end