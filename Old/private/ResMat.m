function [R0,RM]=ResMat(Q,W,EXP)
%===================================================================================
%  function [R0,RM]=ResMat(Q,W,EXP)
%  ResLib v.3.4
%===================================================================================
%
%  For a momentum transfer Q and energy transfers W,
%  given experimental conditions specified in EXP,
%  calculates the Cooper-Nathans resolution matrix RM and
%  Cooper-Nathans Resolution prefactor R0.
%
% A. Zheludev, 1999-2006
% Oak Ridge National Laboratory
%====================================================================================

% 0.424660900144 = FWHM2RMS
% CONVERT1=0.4246609*pi/60/180;
CONVERT1=pi/60/180; % TODO: FIX constant from CN. 0.4246
CONVERT2=2.072;

len = 1; % vectors are treated in ResLibCal_ComputeResMat. We get rid of CleanArgs.
% [len,Q,W,EXP]=CleanArgs(Q,W,EXP);

RM=zeros(4,4,len);
R0=zeros(1,len);
RM_=zeros(4,4);
D=zeros(8,13);
d=zeros(4,7);
T=zeros(4,13);
t=zeros(2,7);
A=zeros(6,8);
C=zeros(4,8);
B=zeros(4,6);

if ischar(EXP.method)
  if ~isempty(strfind(lower(EXP.method), 'cooper')) EXP.method=0; 
  else                                              EXP.method=1; 
  end
end

for ind=1:len
    %---------------------------------------------------------------------------------------------
    % the method to use
    method=0;
    if isfield(EXP(ind),'method')
        method=EXP(ind).method;
    end;
    
    %Assign default values and decode parameters
    moncor=0;
    if isfield(EXP(ind),'moncor')
        moncor = EXP(ind).moncor;
    end;
    alpha = EXP(ind).hcol*CONVERT1;
    beta =  EXP(ind).vcol*CONVERT1;
    mono=EXP(ind).mono;
    etam = mono.mosaic*CONVERT1;
    etamv=etam;
    if isfield(mono,'vmosaic')
        etamv = mono.vmosaic*CONVERT1;
    end;
    ana=EXP(ind).ana;
    etaa = ana.mosaic*CONVERT1;
    etaav=etaa;
    if isfield(ana,'vmosaic')
        etaav = ana.vmosaic*CONVERT1;
    end;
    sample=EXP(ind).sample;
    infin=-1;
    if isfield(EXP(ind),'infin')
        infin = EXP(ind).infin;
    end;
    efixed=EXP(ind).efixed;
    epm=1;
    if isfield(EXP(ind),'dir1')
        epm= EXP(ind).dir1;
    end;
    ep=1;
    if isfield(EXP(ind),'dir2')
        ep= EXP(ind).dir2;
    end;
    monitorw=1;
    monitorh=1;
    beamw=1;
    beamh=1;
    monow=1;
    monoh=1;
    monod=1;
    anaw=1;
    anah=1;
    anad=1;
    detectorw=1;
    detectorh=1;
    sshape=eye(3);
    L0=1;
    L1=1;
    L1mon=1;
    L2=1;
    L3=1;        
    monorv=1e6;
    monorh=1e6;
    anarv=1e6;
    anarh=1e6;
    if isfield(EXP(ind),'beam')
        beam=EXP(ind).beam;
        if isfield(beam,'width')
            beamw=beam.width^2/12;
        end;
        if isfield(beam,'height')
            beamh=beam.height^2/12;
        end;
    end;
    bshape=diag([beamw,beamh]);
    if isfield(EXP(ind),'monitor')
        monitor=EXP(ind).monitor;
        if isfield(monitor,'width')
            monitorw=monitor.width^2/12;
        end;
        monitorh=monitorw;
        if isfield(monitor,'height')
            monitorh=monitor.height^2/12;
        end;
    end;
    monitorshape=diag([monitorw,monitorh]);
    if isfield(EXP(ind),'detector')
        detector=EXP(ind).detector;
        if isfield(detector,'width')
            detectorw=detector.width^2/12;
        end;
        if isfield(detector,'height')
            detectorh=detector.height^2/12;
        end;
    end;
    dshape=diag([detectorw,detectorh]);
    if isfield(mono,'width')
        monow=mono.width^2/12;
    end;
    if isfield(mono,'height')
        monoh=mono.height^2/12;
    end;
    if isfield(mono,'depth')
        monod=mono.depth^2/12;
    end;
    mshape=diag([monod,monow,monoh]);
    if isfield(ana,'width')
        anaw=ana.width^2/12;
    end;
    if isfield(ana,'height')
        anah=ana.height^2/12;
    end;
    if isfield(ana,'depth')
        anad=ana.depth^2/12;
    end;
    ashape=diag([anad,anaw,anah]);
    if isfield(sample,'width') && isfield(sample,'depth') && isfield(sample, 'height')
        sshape=diag([ sample.depth sample.width sample.height ].^2/12);
    elseif isfield(sample,'shape')
        sshape=sample.shape/12;
    end;
    if isfield(EXP(ind),'arms')
        arms=EXP(ind).arms;
        L0=arms(1);
        L1=arms(2);
        L2=arms(3);
        L3=arms(4);
        L1mon=L1;
        if length(arms)>4
            L1mon=arms(5);
        end
    end;
    if isfield(mono,'rv')
        monorv=mono.rv;
    end;
    if isfield(mono,'rh')
        monorh=mono.rh;
    end;
    if isfield(ana,'rv')
        anarv=ana.rv;
    end;
    if isfield(ana,'rh')
        anarh=ana.rh;
    end;
    
    taum=GetTau(mono.tau);
    taua=GetTau(ana.tau);

    horifoc=-1;
    % this following correction introduces a discontinuity: we thus ignore it.
    if isfield(EXP(ind),'horifoc')
        % horifoc=EXP(ind).horifoc;
    end;

    if horifoc==1
        alpha(3)=alpha(3)*sqrt(8*log(2)/12);
    end;
    
    em=1;
    if isfield(EXP(ind),'mondir')
        em= EXP(ind).mondir;
    end;
    sm =EXP.mono.dir;
    ss =EXP.sample.dir;
    sa =EXP.ana.dir;
    %---------------------------------------------------------------------------------------------
    %Calculate angles and energies
    w=W(ind);
    q=Q(ind);
    ei=efixed;
    ef=efixed;
    if infin>0 ef=efixed-w; else ei=efixed+w; end;
    ki = sqrt(ei/CONVERT2);
    kf = sqrt(ef/CONVERT2);
    
    thetam=asin(taum/(2*ki))*sm; % added sign(em) K.P.
    thetaa=asin(taua/(2*kf))*sa; 
    s2theta=acos( (ki^2+kf^2-q^2)/(2*ki*kf))*ss; %2theta sample
    if ~isreal(s2theta) 
        % disp([ datestr(now) ': ' mfilename ': KI,KF,Q triangle will not close (kinematic equations). Change the value of KFIX,FX,QH,QK or QL.' ]);
        % disp([EXP.QH EXP.QK EXP.QL W])
        R0=0; RM=[];
        return
    end
    
    % correct sign of curvature
    monorh = monorh*sm;
    monorv = monorv*sm;
    anarh  = anarh*sa;
    anarv  = anarv*sa;

    thetas=s2theta/2;
    phi=atan2(-kf*sin(s2theta), ki-kf*cos(s2theta));
     %------------------------------------------------------------------
    %Redefine sample geometry
    psi=thetas-phi; %Angle from sample geometry X axis to Q
    rot=zeros(3,3);
    rot(1,1)=cos(psi);
    rot(2,2)=cos(psi);
    rot(1,2)=sin(psi);
    rot(2,1)=-sin(psi);
    rot(3,3)=1;
%    sshape=rot'*sshape*rot;
    sshape=rot*sshape*rot';

    %-------------------------------------------------------------------
    %Definition of matrix G    
    G=1./([alpha(1),alpha(2),beta(1),beta(2),alpha(3),alpha(4),beta(3),beta(4)]).^2;
    G=diag(G);
 %----------------------------------------------------------------------
    %Definition of matrix F    
    F=1./([etam,etamv,etaa,etaav]).^2;
    F=diag(F);

    %-------------------------------------------------------------------
    %Definition of matrix A
    A(1,1)=ki/2/tan(thetam);
    A(1,2)=-A(1,1);
    A(4,5)=kf/2/tan(thetaa);
    A(4,6)=-A(4,5);
    A(2,2)=ki;
    A(3,4)=ki;
    A(5,5)=kf;
    A(6,7)=kf;

    %-------------------------------------------------------------------
    %Definition of matrix C
    C(1,1)=1/2;
    C(1,2)=1/2;
    C(3,5)=1/2;
    C(3,6)=1/2;
    C(2,3)=1/(2*sin(thetam));
    C(2,4)=-C(2,3); %mistake in paper
    C(4,7)=1/(2*sin(thetaa));
    C(4,8)=-C(4,7);
    
    %-------------------------------------------------------------------
    %Definition of matrix B
    B(1,1)=cos(phi);
    B(1,2)=sin(phi);
    B(1,4)=-cos(phi-s2theta);
    B(1,5)=-sin(phi-s2theta);
    B(2,1)=-B(1,2);
    B(2,2)=B(1,1);
    B(2,4)=-B(1,5);
    B(2,5)=B(1,4);
    B(3,3)=1;
    B(3,6)=-1;
    B(4,1)=2*CONVERT2*ki;
    B(4,4)=-2*CONVERT2*kf;
 %----------------------------------------------------------------------
    %Definition of matrix S
    Sinv=blkdiag(bshape,mshape,sshape,ashape,dshape); %S-1 matrix     
    S=Sinv^(-1);
    %---------------------------------------------------------------------------------------------
    %Definition of matrix T
    T(1,1)=-1/(2*L0);  %mistake in paper
    T(1,3)=cos(thetam)*(1/L1-1/L0)/2;
    T(1,4)=sin(thetam)*(1/L0+1/L1-2/(monorh*sin(thetam)))/2;
    T(1,6)=sin(thetas)/(2*L1);
    T(1,7)=cos(thetas)/(2*L1);
    T(2,2)=-1/(2*L0*sin(thetam));
    T(2,5)=(1/L0+1/L1-2*sin(thetam)/monorv)/(2*sin(thetam));
    T(2,8)=-1/(2*L1*sin(thetam));
    T(3,6)=sin(thetas)/(2*L2);
    T(3,7)=-cos(thetas)/(2*L2);
    T(3,9)=cos(thetaa)*(1/L3-1/L2)/2;
    T(3,10)=sin(thetaa)*(1/L2+1/L3-2/(anarh*sin(thetaa)))/2;
    T(3,12)=1/(2*L3);
    T(4,8)=-1/(2*L2*sin(thetaa));
    T(4,11)=(1/L2+1/L3-2*sin(thetaa)/anarv)/(2*sin(thetaa));
    T(4,13)=-1/(2*L3*sin(thetaa));
    %-------------------------------------------------------------------
    %Definition of matrix D
    % Lots of index mistakes in paper for matrix D
    D(1,1)=-1/L0;
    D(1,3)=-cos(thetam)/L0;
    D(1,4)=sin(thetam)/L0;
    D(3,2)=D(1,1);
    D(3,5)=-D(1,1);
    D(2,3)=cos(thetam)/L1;
    D(2,4)=sin(thetam)/L1;
    D(2,6)=sin(thetas)/L1;
    D(2,7)=cos(thetas)/L1;
    D(4,5)=-1/L1;
    D(4,8)=-D(4,5);
    D(5,6)=sin(thetas)/L2;
    D(5,7)=-cos(thetas)/L2;
    D(5,9)=-cos(thetaa)/L2;
    D(5,10)=sin(thetaa)/L2;
    D(7,8)=-1/L2;
    D(7,11)=-D(7,8);
    D(6,9)=cos(thetaa)/L3;
    D(6,10)=sin(thetaa)/L3;
    D(6,12)=1/L3;
    D(8,11)=-D(6,12);
    D(8,13)=D(6,12);
    
 %----------------------------------------------------------------------
    %Definition of resolution matrix M
    if method==1 || strcmpi(method, 'Popovici')
        K = S+T'*F*T;
        H = inv(D*inv(K)*D');
        Ninv = A*inv(H+G)*A'; % Popovici Eq 20
    else                      % method=0: Cooper-Nathans in Popovici formulation
        H = G+C'*F*C;                       % Popovici Eq 8
        Ninv= A*inv(H)*A';                  % Cooper-Nathans (in Popovici Eq 10)
        %Horizontally focusing analyzer if needed. Does not depend on RAH, so we ignore it.
        if horifoc>0
            Ninv=inv(Ninv);
            Ninv(5,5)=(1/(kf*alpha(3)))^2; 
            Ninv(5,4)=0; 
            Ninv(4,5)=0; 
            Ninv(4,4)=(tan(thetaa)/(etaa*kf))^2;
            Ninv=inv(Ninv);
        end
    end;
    Minv=B*Ninv*B'; % Popovici Eq 3

    % TODO: FIX added factor 5.545 from ResCal5
    M=8*log(2)*inv(Minv);  % Correction factor 8*log(2) as input parameters
                        % are expressed as FWHM.

    % TODO: rows-columns 3-4 swapped for ResPlot to work. 
    % Inactivate as we want M=[x,y,z,E]
%    RM_(1,1)=M(1,1);
%    RM_(2,1)=M(2,1);
%    RM_(1,2)=M(1,2);
%    RM_(2,2)=M(2,2);
%    
%    RM_(1,3)=M(1,4);
%    RM_(3,1)=M(4,1);
%    RM_(3,3)=M(4,4);
%    RM_(3,2)=M(4,2);
%    RM_(2,3)=M(2,4);
%    
%    RM_(1,4)=M(1,3);
%    RM_(4,1)=M(3,1);
%    RM_(4,4)=M(3,3);
%    RM_(4,2)=M(3,2);
%    RM_(2,4)=M(2,3);
    %-------------------------------------------------------------------
    %Calculation of prefactor, normalized to source
    Rm  = ki^3/tan(thetam); 
    Ra  = kf^3/tan(thetaa);
    R0_ = Rm*Ra*(2*pi)^4/(64*pi^2*sin(thetam)*sin(thetaa));
    
    if method==1 || strcmpi(method, 'Popovici')
        R0_=R0_ *sqrt(det(F)/det( H+G ));      %Popovici
    else
        R0_=R0_ *sqrt(det(F)/det( H )); %Cooper-Nathans (popovici Eq 5 and 9)
        % difference in R0 comes from the horifoc correction on alpha(3)
    end

    %-------------------------------------------------------------------

    %Normalization to flux on monitor
    if moncor==1
        g=G(1:4,1:4);
        f=F(1:2,1:2);
        c=C(1:2,1:4);
        if method==1 || strcmpi(method, 'Popovici')
          t(1,1)=-1/(2*L0);  %mistake in paper
          t(1,3)=cos(thetam)*(1/L1mon-1/L0)/2;
          t(1,4)=sin(thetam)*(1/L0+1/L1mon-2/(monorh*sin(thetam)))/2;
          t(1,7)=1/(2*L1mon);
          t(2,2)=-1/(2*L0*sin(thetam));
          t(2,5)=(1/L0+1/L1mon-2*sin(thetam)/monorv)/(2*sin(thetam));
          sinv=blkdiag(bshape,mshape,monitorshape); %S-1 matrix        
          s=sinv^(-1);
          d(1,1)=-1/L0;
          d(1,3)=-cos(thetam)/L0;
          d(1,4)=sin(thetam)/L0;
          d(3,2)=D(1,1);
          d(3,5)=-D(1,1);
          d(2,3)=cos(thetam)/L1mon;
          d(2,4)=sin(thetam)/L1mon;
          d(2,6)=0;
          d(2,7)=1/L1mon;
          d(4,5)=-1/L1mon;
          Rmon=Rm*(2*pi)^2/(8*pi*sin(thetam))*sqrt( det(f)/det((d*(s+t'*f*t)^(-1)*d')^(-1)+g)); %Popovici
        else
          Rmon=Rm*(2*pi)^2/(8*pi*sin(thetam))*sqrt( det(f)/det(g+c'*f*c)); %Cooper-Nathans
        end;
        R0_=R0_/Rmon;
        R0_=R0_*ki; %1/ki monitor efficiency
    end;
    %---------------------------------------------------------------------------
    %Transform prefactor to Chesser-Axe normalization
    R0_=R0_/(2*pi)^2*sqrt(det(M));
    %---------------------------------------------------------------------------
    %Include kf/ki part of cross section
    R0_=R0_*kf/ki;
    %---------------------------------------------------------------------------
    % Take care of sample mosaic if needed 
    % [S. A. Werner & R. Pynn, J. Appl. Phys. 42, 4736, (1971), eq 19]
    if isfield(sample,'mosaic')
        etas = sample.mosaic*CONVERT1;
        if isfield(sample,'vmosaic')
            etasv = sample.vmosaic*CONVERT1;
        end
        % TODO: FIX changed RM_(4,4) and M(4,4) to M(3,3)
        R0_=R0_/sqrt((1+(q*etasv)^2*M(3,3))*(1+(q*etas)^2*M(2,2)));
        %Minv=RM_^(-1);
        Minv(2,2)=Minv(2,2)+q^2*etas^2;
        Minv(3,3)=Minv(3,3)+q^2*etasv^2;
        % TODO: FIX add 8*log(2) factor for mosaicities in FWHM
        M=8*log(2)*inv(Minv);
    end;
    %---------------------------------------------------------------------------
    %Take care of analyzer reflectivity if needed [I. Zaliznyak, BNL]
    if isfield(ana,'thickness') && isfield(ana,'Q')         
        KQ = ana.Q;
        KT = ana.thickness;
        toa=(taua/2)/sqrt(kf^2-(taua/2)^2);
        smallest=alpha(4);
        if alpha(4)>alpha(3) smallest=alpha(3); end;
        Qdsint=KQ*toa;
        dth=((1:201)/200).*sqrt(2*log(2))*smallest;
        wdth=exp(-dth.^2/2./etaa^2);
        sdth=KT*Qdsint*wdth/etaa/sqrt(2.*pi);
        rdth=1./(1+1./sdth);
        reflec=sum(rdth)/sum(wdth);
        R0_=R0_*reflec;
    end;
    
    %---------------------------------------------------------------------------
    R0(ind)=R0_;
    RM(:,:,ind)=M(:,:);
end;%for





