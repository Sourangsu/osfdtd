%% ========================================================================
% Written by: Sourangsu Banerji, University of Utah
% Verified by: Manjunath Machnoor, University of Southern California
%% ========================================================================

%% code for 2D FDTD (TM mode wave propagation-PML boundary condition)
%% workspace definition
close all;
clear all;
clc;

%%parameter definition (material - source - structure definition - boundary condition)
IE = 60;                                                                   %number of cells to be used
JE = 60;                                                                   %number of cells to be used

%material definition
epsz = 8.85419e-12;

%source definition
ic = IE/2;
jc = JE/2;
pi = 3.14159;
to = 40;                                                                   %center of the incident pulse
spread = 15;                                                               %width of the incident pulse
ddx = 0.01;                                                                %spatial sampling
dt = ddx/(2*3e8);                                                          %temporal interval (could be derived from courant stability factor)

T = 0;
Nsteps = 1;

for j = 1:JE
    for i = 1:IE
        dz(i,j) = 0;
        hx(i,j) = 0;
        hy(i,j) = 0;
        ihx(i,j) = 0;
        ihy(i,j) = 0;
        ga(i,j) = 1;
    end
end

for i = 1:IE
    gi2(i) = 1;
    gi3(i) = 1;
    fi1(i) = 0;
    fi2(i) = 1;
    fi3(i) = 1;
end

for j = 1:IE
    gj2(j) = 1;
    gj3(j) = 1;
    fj1(j) = 0;
    fj2(j) = 1;
    fj3(j) = 1;
end

prompt = 'What is the number of PML cells you wish to use? ';
npml = input(prompt);

for i = 1:npml
    xnum = npml - i;
    xd = npml;
    xxn = xnum/xd;
    xn = (0.33)*power(xxn,3);
    gi2(i) = 1/(1+xn);
    gi2(IE-1-i) = 1/(1+xn);
    gi3(i) = (1-xn)/(1+xn);
    gi3(IE-i-1) = (1-xn)/(1+xn);
    xxn = (xnum-0.5)/xd;
    xn = (0.25)*power(xxn,3);
    fi1(i) = xn;
    fi1(IE-2-i) = xn;
    fi2(i) = 1/(1+xn);
    fi2(IE-2-i) = 1/(1+xn);
    fi3(i) = (1-xn)/(1+xn);
    fi3(IE-2-i) = (1-xn)/(1+xn);
end

for j = 1:npml
    xnum = npml - j;
    xd = npml;
    xxn = xnum/xd;
    xn = (0.33)*power(xxn,3);
    gj2(j) = 1/(1+xn);
    gj2(JE-1-j) = 1/(1+xn);
    gj3(j) = (1-xn)/(1+xn);
    gj3(JE-j-1) = (1-xn)/(1+xn);
    xxn = (xnum-0.5)/xd;
    xn = (0.25)*power(xxn,3);
    fj1(j) = xn;
    fj1(JE-2-j) = xn;
    fj2(j) = 1/(1+xn);
    fj2(JE-2-j) = 1/(1+xn);
    fj3(j) = (1-xn)/(1+xn);
    fj3(JE-2-j) = (1-xn)/(1+xn);
end

%% Warning!! Don't change code from here!!
while (Nsteps > 0)
    n = 0;
    
    for n = 1:Nsteps                                                       %Nsteps is the number of times the main loop has executed
        T =T+1;                                                            %T keeps track of the timesteps
        %main fdtd loop
        
        %calculate the Dz field
        for j = 2:IE
            for i = 2:IE
                dz(i,j) = gi3(i)*gj3(j)*dz(i,j) + gi2(i)*gj2(j)*0.5*(hy(i,j)-hy(i-1,j)-hx(i,j)+hx(i,j-1));
            end
        end
        
        %put pulse in the specified grid position
        pulse =  sin(2*pi*1500*1e6*dt*T);
        dz(ic,jc) = pulse;
        
        %calculate Ez from Dz
        for j = 2:JE
            for i = 2:IE
                ez(i,j) = ga(i,j) * dz(i,j);
            end
        end
        
        %set the Ez edges to 0 as part of the PML
        for j = 1:JE-1
            ez(1,j) = 0;
            ez(IE-1,j) = 0;
        end
        
        for i = 1:IE-1
            ez(i,1) = 0;
            ez(i,JE-1) = 0;
        end
        
        %calculate the Hx field
        for j = 1:JE-1
            for i = 1:IE-1
                curl_e = ez(i,j) - ez(i,j+1);
                ihx(i,j) = ihx(i,j) + fi1(i)*curl_e;
                hx(i,j) = fj3(j)*hx(i,j) + fj2(j)*0.5*(curl_e + ihx(i,j));
            end
        end
        
        %calculate the Hy field
        for j = 1:JE-1
            for i = 1:IE-1
                curl_e = ez(i+1,j) - ez(i,j);
                ihy(i,j) = ihy(i,j) + fj1(j)*curl_e;
                hx(i,j) = fj3(i)*hy(i,j) + fi2(i)*0.5*(curl_e + ihy(i,j));
            end
        end
    end
    
    pause(0.2);
    fprintf('Timestep = %f \n',T);
    surf(ez);

end

