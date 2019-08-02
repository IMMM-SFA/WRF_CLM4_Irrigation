%---------- Anjana , 5 Aug 2018 -------------
% Script checks to ensure that fgrd and fsurf add to one (interpolation of 0.5 deg irrigation data to model grid causes minor mismatch at the edges)
% Script also does checks to ensure that the total crop area in a grid cell is less than 85% (constraint based on MODIS LU to PFT mapping in WRF-CLM4)
% There are few grid cells in the South Asia model domain where crop area > 85%, they are reset to 85%
% For grid cells that are mapped from IVGTYP 14 to PFTs, the limit is 50%. (Very few grid cells correspond to IVGTYP 14)
%--------------------------------------------

   count=0;
   count_d=0;
   
   filename = ['wrfinput_d01'];
   
   fgrd = ncread(filename,'F_GRD');
   fsurf = ncread(filename,'F_SURF');
   area_frac = ncread(filename,'AREA_FRAC');
   ivgtyp = double(ncread(filename,'IVGTYP'));
   paddy_irrig_frac = ncread(filename,'PADDY_IRRIG_FRAC');
   paddy_rainfed_frac = ncread(filename,'PADDY_RAINFED_FRAC');
   irrig_wateruse = ncread(filename,'IRRIG_WATERUSE');

   ivgtyp12=ivgtyp;
   ivgtyp12(ivgtyp12~=12)=NaN;

   ivgtyp14=ivgtyp;
   ivgtyp14(ivgtyp14~=14)=NaN;

   area_frac(area_frac>85)=85;   
   area_frac_ivg14 = area_frac;
   area_frac_ivg14(isnan(ivgtyp14))=NaN;
   area_frac(area_frac_ivg14>50)=50; %replacing only ivt14's > 50
  
   fsum=fgrd+fsurf; 
   
   for i_x=1:size(ivgtyp,1)
       for i_y=1:size(ivgtyp,2)
           
           pt_fsum=fsum(i_x,i_y);
           pt_fgrd=fgrd(i_x,i_y);
           pt_fsurf=fsurf(i_x,i_y);
           
           if(pt_fsum>1)
               count=count+1;
               excess=pt_fsum-1;
               fgrd_new=pt_fgrd-(excess/2);
               fsurf_new=pt_fsurf-(excess/2);
               fgrd(i_x,i_y)=fgrd_new; 
               fsurf(i_x,i_y)=fsurf_new;
               clear fgrd_new fsurf_new excess
           end
                
           if((pt_fsum<1) && (pt_fsum>0))
               count_d=count_d+1;
               deficit=1-pt_fsum;
               fgrd_new=pt_fgrd+(deficit/2);
               fsurf_new=pt_fsurf+(deficit/2);
               fgrd(i_x,i_y)=fgrd_new;
               fsurf(i_x,i_y)=fsurf_new;
               clear fgrd_new fsurf_new deficit
           end            
           
       end
   end
   
    crop_tot = area_frac + paddy_rainfed_frac;
    
    if(size(find(crop_tot>85),1)>0)
        ['crop>85']
        area_frac_temp = 85-paddy_rainfed_frac;
        area_frac_new = area_frac;
        area_frac_new(crop_tot>85)=area_frac_temp(crop_tot>85); %replacing only grids with crop_tot>85
        area_frac=area_frac_new;
    end
    clear crop_tot
    clear area_frac_temp area_frac_new
    
    paddy_irrig_frac_ivg14 = paddy_irrig_frac;
    paddy_irrig_frac_ivg14(isnan(ivgtyp14))=NaN;
    area_frac_ivg14 = area_frac;
    area_frac_ivg14(isnan(ivgtyp14))=NaN;
    paddy_rainfed_frac_ivg14 = paddy_rainfed_frac;
    paddy_rainfed_frac_ivg14(isnan(ivgtyp14))=NaN;
    
    crop_tot = area_frac_ivg14+paddy_rainfed_frac_ivg14;
    
    if(size(find(crop_tot>50),1)>0)
        ['crop14>50']
        area_frac_temp = 50-paddy_rainfed_frac;
        area_frac_new = area_frac;
        area_frac_new(crop_tot>50)=area_frac_temp(crop_tot>50); %replacing only ivt14's > 50
        area_frac=area_frac_new;
    end
    
    %area_frac_test = ncread(filename,'AREA_FRAC');
    %figure(1)
    %imagesc(area_frac_test)
    
    %area_frac_ivg14 = area_frac_test;
    %area_frac_ivg14(isnan(dom25_ivgtyp14))=NaN;
    %paddy_rainfed_frac_ivg14 = paddy_rainfed_frac;
    %paddy_rainfed_frac_ivg14(isnan(dom25_ivgtyp14))=NaN;
    
    %crop_tot = area_frac_ivg14+paddy_rainfed_frac_ivg14;
    %find(crop_tot>50)
    %paddy_check = area_frac_test-paddy_irrig_frac;
    %find(paddy_check<0)

   fgrd(isnan(fgrd))=0.5;
   fsurf(isnan(fsurf))=0.5;
   area_frac(isnan(area_frac))=0;
   irrig_wateruse(isnan(irrig_wateruse))=0;
   
   %fsum2=fsurf+fgrd;
   %size(find(fsum2<1))
   %size(find(fsum2>1))
   
   ncwrite(filename,'F_GRD',fgrd);
   ncwrite(filename,'F_SURF',fsurf);
   ncwrite(filename,'AREA_FRAC',area_frac);
   ncwrite(filename,'IRRIG_WATERUSE',irrig_wateruse);   
