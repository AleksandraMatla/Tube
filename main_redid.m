%%%%%% Load .wav File %%%%%%
[input_data, input_fs] = audioread('mouthpiece_stereo.wav');
cut_value = 130000;
input_data = input_data(1:cut_value,2);

%%%%%% Global Parameters %%%%%%
SR = 2*44100;                     % Sample rate (Hz)
f0 = 441;                         % Fundamental frequency (Hz)
TF = 2;                           % Duration of simulation (s)
rp = 0.98;                         % Position of readout (0-1)

%%%%%% Derived Parameters %%%%%%
k = 1/SR;                         % Time step
NF = floor(SR*TF);                % Duration of simulation (samples)
%N = floor(0.5*SR/f0);            % Length of delay lines
N = floor((0.25/340)*SR);
rp_int = 1 + floor(N*rp);         % Rounded grid index for readout
rp_frac = 1 + rp*N - rp_int;      % Fractional part of readout location

df = 1;
db = 1;

data = load('segments.txt');
numSegments = size(data, 1);

tube = cell(1, numSegments);      % Initialize tube object

%%%%% Initialize Each Segment Object %%%%%%
for i = 1:numSegments
    Sn = data(i, 1);
    Sn1 = data(i, 2);
    rl = (Sn1-Sn)/(Sn1+Sn);
    Wr = zeros(N,1);
    Wl = zeros(N,1);
    tube{i} = Tube(N, rl, Wr, Wl); % Pass N, rl, Wr, Wl to the Tube constructor
end

%%%%%% Main Loop: Simulate Wave Propagation %%%%%%

for i = 1:NF
    for l = 1:numSegments
        if l == 1
            tube{l}.temp1 = tube{l}.wright(N);
            tube{l}.temp2 = tube{l}.wleft(1);
            tube{l}.wright(2:N) = tube{l}.wright(1:N-1);
            %tube{l}.wright(1) = input_data(mod(i-1,cut_value)+1);
            tube{l}.wright(1) = 1;
            tube{l}.wleft(1:N-1) = tube{l}.wleft(2:N);
            tube{l}.wright(1) = tube{l}.wright(1) + df * tube{l}.temp2;
            tube{l}.wleft(N) = tube{l}.M11 * tube{l}.temp1 + tube{l}.M12 * tube{l+1}.temp2;

        elseif l == numSegments
            tube{l}.temp1 = tube{l}.wright(N);
            tube{l}.temp2 = tube{l}.wleft(1);
            tube{l}.wright(2:N) = tube{l}.wright(1:N-1);
            tube{l}.wright(1) = tube{l-1}.M21 * tube{l-1}.temp1;
            tube{l}.wleft(1:N-1) = tube{l}.wleft(2:N);
            tube{l}.wright(1) = tube{l}.wright(1) + tube{l-1}.M22 * tube{l}.temp2;
            tube{l}.wleft(N) = db * tube{l}.temp1;
    
        else
            tube{l}.temp1 = tube{l}.wright(N);
            tube{l}.temp2 = tube{l}.wleft(1);
            tube{l}.wright(2:N) = tube{l}.wright(1:N-1);
            tube{l}.wright(1) = tube{l-1}.M21 * tube{l-1}.temp1;
            tube{l}.wleft(1:N-1) = tube{l}.wleft(2:N);
            tube{l}.wright(1) = tube{l}.wright(1) + tube{l-1}.M22 * tube{l}.temp2;
            tube{l}.wleft(N) = tube{l}.M11 * tube{l}.temp1 + tube{l}.M12 * tube{l+1}.temp2;
        end
    end

    out(i) = (1 - rp_frac) * (tube{1}.wleft(rp_int) + tube{1}.wright(rp_int)) ...
        + rp_frac * (tube{1}.wleft(rp_int+1) + tube{1}.wright(rp_int+1));
end

%%%%%% Plot Output Waveform %%%%%%
plot([0:NF-1] * k, out, 'b');
xlabel('Time (s)');
ylabel('Displacement');
title('Sound Propagation in a Tube: Digital Waveguide Synthesis Output');
axis tight
axis tight

%%%%% Save Output as .wav File %%%%%%
filename = 'tube_simulation.wav';
audiowrite(filename, out, SR);
