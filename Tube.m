classdef Tube
    properties
        wright
        wleft
        M11
        M12
        M21
        M22
        temp1
        temp2
    end
    methods
        function obj = Tube(N, rl, Wl, Wr)
            obj.wleft = Wl;
            obj.wright = Wr;
            obj.temp1 = obj.wright(N);
            obj.temp2 = obj.wleft(1);
            obj.M11 = - rl;
            obj.M12 = 1 - rl;
            obj.M21 = 1 + rl;
            obj.M22 = rl;
        end
    end
end
