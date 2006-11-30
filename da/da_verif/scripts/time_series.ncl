;===========================================================================================;
;  time_series.ncl
;ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
; Copyright (C) 2006
; University Corporation for Atmospheric Research
; All Rights Reserved
;ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
; Author: Ananda Kumar Das (Visiting Scientist)
;         National Center for Atmospheric Research 
;         Boulder, CO 80301
;
; Date: 11/27/06
;=========================================================;
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;===========================================================================================;
begin
;===========================================================================================;
num_legend=dimsizes(exp_line_cols) + 1
legend_line_cols=new((/num_legend/),"string")
legend_line_cols(0:num_legend-2)=exp_line_cols(0:num_legend-2)
legend_line_cols(num_legend-1)="black"

delete(num_legend)
num_legend=dimsizes(exp_legends) + 1
new_legends=new((/num_legend/),"string")
new_legends(0:num_legend-2)=exp_legends(0:num_legend-2)
new_legends(num_legend-1)="Obs Num"
;-----------------------------------------------------------
num_d_levs=dimsizes(select_levs)
num_d_scor=dimsizes(select_scores)
;-----------------------------------------------------------
; open file and read in data
;-----------------------------------------------------------
run_dir=run_dir+"/"
plot_dir = run_dir
read_headers = asciiread(run_dir+"header_main",-1,"string")
;-----------------------------------------------------------
Xaxis_title = read_headers(0)
diag_var = read_headers(1)
num_expt = stringtointeger(read_headers(2))
pdat_dirs = (/read_headers(3 : 2+num_expt(0))/)
;-----------------------------------------------------------
num_obs = dimsizes(read_headers) - (num_expt + 3)
fnames_obs = new((/num_obs/),"string")
do iob = 1, num_obs
fnames_obs(iob-1)= read_headers(num_expt+3+iob-1)
end do
;-----------------------------------------------------------
;-----------------------------------------------------------
do iob = 1, num_obs
;------------------
;------------------
varheads = asciiread(run_dir+fnames_obs(iob-1),-1,"string")
nrow = stringtointeger(varheads(0))
ncol = stringtointeger(varheads(1))
varnames = (/varheads(2 : :)/) 

num_vars = dimsizes(varnames)/2
varfiles = new((/num_vars/),"string")
varunits = new((/num_vars/),"string")

do iv = 1, num_vars
  varfiles(iv-1)= varnames(2*(iv-1))
  varunits(iv-1)= varnames(2*(iv-1)+1)
end do
;----------------------------------------------------------
dfile=pdat_dirs(0)+varfiles(0)
dates = new((/nrow/),"float")
dates = stringtofloat(systemfunc("cut -c8-9 " + dfile)) 
nxx = dimsizes(dates)
;----------------------------------------------------------
sfc_file="fnames_sfc"
if ( fnames_obs(iob-1) .eq. sfc_file ) then
 nlev =1
 ifsfc = True
 out_name="Surface_"
else
 nlev = 16
 ifsfc = False
 out_name="Upper-air_"
end if
;--------------------------------------------
q_levels = 9
nv = num_vars
nexp = num_expt
;
data = new ((/nv,nexp,nrow,ncol/),"float")

do iexp = 1, nexp
do iv = 1, nv
  data((iv-1),(iexp-1),:,:)=asciiread(pdat_dirs(iexp-1)+varfiles(iv-1),(/nrow,ncol/),"float")
end do
end do
;********************************************************************************************
; Data Format:  In each row total (1 + 16 x 4 = 65) values for Upper-air
; Data Format:  In each row total (1 + 1 x 4 = 5) values for Surface
;
; Date,  For each level triplets for NUM, BIAS Absolute BIAS & RMSE 
; levels:  1000 925 850 700 500 400 300 250 200 150 100 70 50 30 20 10
; index      1   2   3   4   5   6   7   8   9  10  11  12 13 14 15 16
;
;   Type :   1     2       3
;          BIAS  ABIAS    RMSE
;********************************************************************************************
 plevels=(/1000,925,850,700,500,400,300,250,200,150,100,70,50,30,20,10/)
;********************************************************************************************
 diag_types=(/"BIAS","ABIAS","RMSE"/)	
 diag_names=(/"Bias","Absolute Bias","RMSE"/) 
;----------------------------------------------------------
 Fill_ValueF = -99.99
 Fill_ValueI = -99.0
 dvals = (/1.0,1.0,1.0,1.0,0.10/)
;----------------------------------------------------------
do idtype =1, num_d_scor  
  do ii = 1, 3
    if ( select_scores(idtype-1) .eq. diag_types(ii-1) ) then
      Type = ii
    end if
  end do
  diag_name=diag_names(Type-1)
;----------------------------------------------------------
first = True
do idlev = 1, num_d_levs 
   do ll = 1, nlev
     if ( select_levs(idlev-1) .eq. plevels(ll-1) ) then
        ilev = ll
     end if
   end do
;----------------------------------------------------------
if (first) then
  wks   = gsn_open_wks (wksdev,plot_dir+out_name+select_scores(idtype-1))   ; open workstation
  first = False
end if
;----------------------------------------------------------
 if (ifsfc) then
   level = 1
   plevel = "Surface  "
 else
   level=ilev
   plevel = plevels(level-1)+" hPa  "
 end if

;----------------------------------------------------------
 plts                      = new (nv,"graphic")   ; define number of panels

 x = new((/nrow/),"integer")
 y = new((/nv,nexp,nrow/),"float")
 y_num = new((/nv,nrow/),"float")

 x = ispan(1,nrow,1)
;----------------------------------------------------------
do iv = 1, nv
   do iexp = 1, nexp
       do irow = 1, nrow
          y(iv-1,iexp-1,irow-1) = data(iv-1,iexp-1,irow-1,1+(level-1)*4+Type)
          y_num(iv-1,irow-1) = data(iv-1,iexp-1,irow-1,1+(level-1)*4)
       end do
    end do
end do
 y@_FillValue = Fill_ValueF
 y_num@_FillValue = Fill_ValueI

 y = smth9(y,0.50,0.25,False)
;----------------------------------------------------------
 res          = True                              ; plot mods desired
 res@gsnDraw               = False                ; (a) do not draw
 res@gsnFrame              = False                ; (b) do not advance 'frame'
 res@xyLineThicknesses = (/2.0,2.0,2.0,2.0,2.0,2.0,2.0,2.0,2.0,2.0/)    ; make lines thicker
 res@xyLineColors      = legend_line_cols                              ; change line color
 res@xyDashPatterns    = (/0,0,0,0,0,0,0,0,0,0/)                        ; choose dash patterns
 res@xyMarkers       = (/2,2,2,2,2,2,2,2,2,2/)                          ; (none, dot, asterisk)
 res@xyMarkerColors   = res@xyLineColors          ; Marker colors
 res@xyMarkerSizeF   = 0.01                       ; Marker size (default is 0.01)
 res@xyLineLabelFontHeightF = 0.02                ; Font size and color
 res@xyLineLabelFontColor   = 2                   ; for line labels
 res@tmXTBorderOn     = True                      ; set up the top border
 res@tmXTOn           = False                     ; set the top tickmark
 res@tmYRBorderOn     = True                      ; set up the Right border
 res@tmYROn           = False                     ; set the Right tickmark
 res@tiXAxisFont     = "Times-roman"              ; Font for X axis label
 res@tiYAxisFont     = "Times-roman"              ; Font for Y axis label
 res@tiXAxisFontThicknessF  = 2.5
 res@tiYAxisFontThicknessF  = 2.5
 res@tiXAxisFontHeightF     = 0.03                ; Change the font size.
 res@tiYAxisFontHeightF     = 0.03
 res@tiXAxisFontAspectF     = 1.5
 res@tiYAxisFontAspectF     = 1.5
 res@tiXAxisString   = Xaxis_title                ; Label for the X axis
;----------------------------------------------------------
 resN          = True                              ; plot mods desired
 resN@gsnDraw               = False                ; (a) do not draw
 resN@gsnFrame              = False                ; (b) do not advance 'frame'
 resN@xyLineThicknesses = (/1.0,2.0,2.0,2.0,2.0,2.0,2.0,2.0,2.0,2.0/)    ; make lines thicker
 resN@xyLineColors      = (/"black"/)                                    ; change line color
 resN@xyDashPatterns    = (/1,0,0,0,0,0,0,0,0,0/)                        ; choose dash patterns
 resN@xyMarkers       = (/2,2,2,2,2,2,2,2,2,2/)                          ; (none, dot, asterisk)
 resN@xyMarkerColors   = resN@xyLineColors         ; Marker colors
 resN@xyMarkerSizeF   = 0.01                       ; Marker size (default is 0.01)
 resN@xyLineLabelFontHeightF = 0.02                ; Font size and color
 resN@xyLineLabelFontColor   = 2                   ; for line labels
 resN@tmXTBorderOn     = True                      ; set up the top border
 resN@tmXTOn           = False                     ; set the top tickmark
;resN@tmYLBorderOn     = True                      ; set up the Right border
 resN@tmYROn           = True                      ; set the Right tickmark
 resN@tiXAxisFont     = "Times-roman"              ; Font for X axis label
 resN@tiYAxisFont     = "Times-roman"              ; Font for Y axis label
 resN@tiXAxisFontThicknessF  = 2.5
 resN@tiYAxisFontThicknessF  = 2.5
 resN@tiXAxisFontHeightF     = 0.03                ; Change the font size.
 resN@tiYAxisFontHeightF     = 0.03
 resN@tiXAxisFontAspectF     = 1.5
 resN@tiYAxisFontAspectF     = 1.5
 resN@tiXAxisString   = Xaxis_title                ; Label for the X axis
;--------------------------------------------------------------------
if (level .le. q_levels ) then
do iv = 1, nv

 res@tiYAxisString   = varunits(iv-1)             ; Label for the Y axis
 resN@tiYAxisString   = "Numbers"                 ; Label for the Y axis

 plts(iv-1) = gsn_csm_xy2(wks,x,y(iv-1,:,:),y_num(iv-1,:),res,resN)

end do
else
do iv = 1, nv-1

 res@tiYAxisString   = varunits(iv-1)             ; Label for the Y axis
 resN@tiYAxisString   = "Numbers"                 ; Label for the Y axis

 plts(iv-1) = gsn_csm_xy2(wks,x,y(iv-1,:,:),y_num(iv-1,:),res,resN)

end do
 
end if
;--------------------------------------------------------------------------------------
; create panel: panel plots have their own set of resources
;--------------------------------------------------------------------------------------
  resP                  = True                    ; modify the panel plot
  resP@gsnMaximize      = True                    ; maximize panel area
  resP@gsnFrame         = False                   ; don't advance the frame
  resP@gsnPanelXWhiteSpacePercent = 4.	 	  ; increase spacing along Y-axis between panel plots
  resP@gsnPanelYWhiteSpacePercent = 4.	 	  ; increase spacing along Y-axis between panel plots
  resP@gsnPanelRowSpec  = True                    ; specify 1 top, 2 lower level
  resP@lbLabelFontHeightF = 0.008		  ; set font height of Label Bar labels
  resP@gsnPanelBottom   = 0.25			  ; shrink panel plot by setting bottom edge of plot
  resP@gsnPanelTop      = 1.00  		  ; shrink panel plot by setting top edge of plot
  resP@gsnPaperOrientation = "portrait"

  resP@txString   = plevel+"  "+diag_name

 gsn_panel(wks,plts,(/nv-2,2/),resP)                ; now draw as one plot
;-------------------------------------------------------------------------------------
 legend = create "Legend" legendClass wks
    "vpXF"                     : 0.25                    ; position on virtual page
    "vpYF"                     : 0.19
    "vpWidthF"                 : 0.5                     ; width
    "vpHeightF"                : 0.1                     ; height
    "lgPerimOn"                : False                   ; no perimeter
    "lgItemCount"              : (nexp +1)                 ; how many
    "lgLabelsOn"               : False                   ; no default lables
    "lgLineLabelFontHeightF"   : 0.015                   ; font height
    "lgMonoLineThickness"      : True
    "lgLineThicknessF"         : 2.0
    "lgDashIndexes"            : (/0,0,0,0,1/)             ; line paters
    "lgLineLabelStrings"       : new_legends
    "lgLineColors"             : legend_line_cols
    "lgMonoLineLabelFontColor" : True                    ; one label color
  end create
 draw(legend)
;-------------------------------------------------------------------------------------

 frame(wks)
 if (ifsfc) then
   break
 end if
  
end do                            ; level loop over
  delete(wks)
  delete(x)
  delete(y)
  delete(y_num)
end do                            ; Type loop over

delete(varheads)
delete(varnames)
delete(varfiles)
delete(varunits)
delete(data)
delete(plts)

end do

end