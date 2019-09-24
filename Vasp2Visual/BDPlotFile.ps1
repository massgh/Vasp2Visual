﻿#This is plotfile for Bands+DOS Projection plot
#Should not join dynamic content string with others
$SystemVariables=@"
#=================System Variables====================
$((Get-Content .\SysInfo.txt -Raw).Trim() )
"@
$ImportPackages=@'
#====No Edit Below Except Last Few Lines of Legend and File Paths in np.loadtxt('Path/To/File')=====
#====================Loading Packages==============================
import numpy as np
import copy
import matplotlib as mpl
import matplotlib.pyplot as plt
from matplotlib.collections import LineCollection
from matplotlib import colors as mcolors
from matplotlib import rc
import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec
from matplotlib import collections  as mc
mpl.rcParams['axes.linewidth'] = 0.4 #set the value globally
mpl.rcParams['font.serif'] = "STIXGeneral"
mpl.rcParams['font.family'] = "serif"
mpl.rcParams['mathtext.fontset'] = "stix"
'@ #Packages Loaded
#Setup files paths for DOS, leave Bands path as it is.
$foldersList=$(Get-ChildItem -Directory).BaseName #returns list of folder names
Foreach($folder in $foldersList){
if($folder.Contains('DOS') -or $folder.Contains('dos')){#get dos/DOS folder in path
$parent="$folder/"}Else{$parent=$null}} #Updated minimal working values
$LoadFiles=@"
text_x,text_y=textLocation;
#====================Loading Files===================================
data=np.loadtxt('./Projection.txt')
pdos=np.loadtxt('./$($parent)pDOS.txt')
KE=np.loadtxt('./Bands.txt')
data_dos=np.loadtxt('./$($parent)tDOS.txt')
"@  #Files Loaded
$CollectData=@'
K=KE[:,3]; E=KE[:,4:]-E_Fermi; #Seperate KPOINTS and Eigenvalues in memory
D=pdos[:,0]-E_Fermi;TDOS=data_dos[:,1]; eGrid_DOS=int(np.shape(TDOS)[0]/ISPIN); #Energy grid mesh
yh=max(E_Limit);yl=min(E_Limit); nField_DOS=int(np.shape(pdos)[1]-1); #Fields in DOS projection
#============Calculation of ION(s)-Contribution=======
holder=np.zeros((NKPTS,NBANDS*nField_Projection))
holder_dos=np.zeros((eGrid_DOS,nField_DOS))
for i in ProIndices[0]: #Indices for ion to claculate contribution of.
    new_mat=data[i*NKPTS:(i+1)*NKPTS,:]
    new_dos=pdos[i*eGrid_DOS:(i+1)*eGrid_DOS,1:]
    tot_pro=np.add(new_mat,holder)
    tot_dos=np.add(new_dos,holder_dos)
    holder=new_mat
    holder_dos=new_dos
#=================================================================
#=========Seperating Orbital Projection for Bands and DOS==========
get_pro=np.zeros((NKPTS,nField_Projection)); #Defined matrix to pick Bands
def get_rgbProjection(NKPTS_by_nField_Matrix):
    mat_copy=copy.deepcopy(NKPTS_by_nField_Matrix) #copy matrix
    projection=np.zeros((np.shape(E))) #making a matrix to collect projections of one type
    for i in range(0,NBANDS*nField_Projection,nField_Projection):
        projection[:,int(i/nField_Projection)]=(tot_pro[:,i:i+nField_Projection]*mat_copy).sum(axis=1)         
    return projection   
get_dos=np.zeros((eGrid_DOS,nField_DOS)) #Defined matrix to pick DOS
def get_rgbDOS(nGrid_by_nField_Matrix): 
    mat_copy=copy.deepcopy(nGrid_by_nField_Matrix)
    dos_orb=(tot_dos*mat_copy).sum(axis=1)
    return dos_orb        
#==================================================================
#Get (R,G.B) values from projection and Normlalize in plot range
maxEnergy=np.min(E,axis=0); minEnergy=np.max(E,axis=0); #Gets bands in visible energy limits.
max_E=np.max(np.where(maxEnergy <=yh)); min_E=np.min(np.where(minEnergy >=yl))
max_index=np.max(np.where(D[:eGrid_DOS] <=yh)); min_index=np.min(np.where(D[:eGrid_DOS] >=yl))
for i in ProIndices[1]: #projection in red color
    get_pro[:,i]=1;get_dos[:,i]=1;
    red=get_rgbProjection(get_pro)
    red_dos=get_rgbDOS(get_dos)
    get_pro[:,:]=0;get_dos[:,:]=0 #Return back to zero
for j in ProIndices[2]: #projection in green color
    get_pro[:,j]=1;get_dos[:,j]=1;
    green=get_rgbProjection(get_pro)
    green_dos=get_rgbDOS(get_dos)
    get_pro[:,:]=0;get_dos[:,:]=0 #Return back to zero
for k in ProIndices[3]: #projection in blue color
    get_pro[:,k]=1;get_dos[:,k]=1;
    blue=get_rgbProjection(get_pro)
    blue_dos=get_rgbDOS(get_dos)
    get_pro[:,:]=0;get_dos[:,:]=0 #Return back to zero
max_con=max(max(map(max,red[:,min_E:max_E+1])),max(map(max,green[:,min_E:max_E+1])),max(map(max,blue[:,min_E:max_E+1])))
red=red[:,min_E:max_E+1]/max_con;green=green[:,min_E:max_E+1]/max_con;blue=blue[:,min_E:max_E+1]/max_con #Values are ready in E_Limit
red_dos=red_dos[min_index:max_index+1];green_dos=green_dos[min_index:max_index+1]; blue_dos=blue_dos[min_index:max_index+1]; #DOS in E_Limit
Elem_dos=red_dos+blue_dos+green_dos; #ION DOS in E_Limit
E=E[:,min_E:max_E+1]; D=D[min_index:max_index+1]  #Updated energy in E_limit (max_E+1 is to include last band as well,python does not read last point in slices.)
TDOS=TDOS[min_index:max_index+1]; #Updated total DOS
#===============Make Collections======================
E_List=[[[(K[i],E[i,j]),(K[i+1],E[i+1,j])]for i in range(NKPTS-1)]for j in range(np.shape(E)[1])];
rgb_List=[[(red[i:(i+2),j].sum()/2,green[i:(i+2),j].sum()/2,blue[i:(i+2),j].sum()/2,1) for i in range(NKPTS-1)] for j in range (np.shape(E)[1])];
lw_List=[[0.3+8*(red[i,j]+red[i+1,j]+green[i,j]+green[i+1,j]+blue[i,j]+blue[i+1,j])/6 \
 for i in range(NKPTS-1)] for j in range (np.shape(E)[1])]; # 0.3 as residual width
'@ #Date Manged till here.
$PlotData=@'
#=================Plotting============================
plt.figure(figsize=(3.4,2.5))
gs = GridSpec(1,2,width_ratios=(7,3))
ax1 = plt.subplot(gs[0])
ax2 = plt.subplot(gs[1])
ax2.tick_params(direction='in', length=2, width=0.2, colors='k', grid_color='k', grid_alpha=0.8)
def ax_settings(ax, x_ticks, x_labels, x_coord,y_coord,Element):
        ax.tick_params(direction='in', length=2, width=0.2, colors='k', grid_color='k', grid_alpha=0.8)
        ax.set_xticks(x_ticks)
        ax.set_xticklabels(x_labels)
        ax.set_xlim(K[0],K[-1])
        ax.set_ylim(yl,yh)
        ax.text(x_coord,y_coord,r"$\mathrm{%s}^{\mathrm{%s}}$" % (SYSTEM, Element),bbox=dict(edgecolor='white',facecolor='white', alpha=0.6),transform=ax.transAxes,color='red') 
        return None
#Lines at KPOINTS
kpts1=[[(K[ii],yl),(K[ii],yh)] for ii in tickIndices[1:-1]];
k_segments= LineCollection(kpts1,colors='k', linestyle='dashed',linewidths=(0.5),alpha=(0.6))
ax1.add_collection(k_segments)
ax1.plot([K[0],K[-1]],[0,0],'k',linewidth=0.3,linestyle='dashed',alpha=0.6) #Horizontal Line
#Full Data Plot
for i in range(np.shape(E)[1]):
    line_segments = LineCollection(E_List[i],colors=rgb_List[i], linestyle='solid',linewidths=lw_List[i])
    ax1.add_collection(line_segments)
ax1.autoscale_view()
ax1.set_ylabel(r'$E-E_F$(eV)')
ax1.set_xlabel('High Symmetry Path');
ticks=[K[ii] for ii in tickIndices];ticklabels[-1]=str(ticklabels[-1]) +"/"+ str(np.round(DOS_Limit[0],1))
ax_settings(ax1,ticks,ticklabels,text_x,text_y,ProLabels[0])
#=============Dummy Plots for Legend====================================
ax2.plot([],[],color=((167/300, 216/300, 222/300)),linewidth=2,label='Total');
ax2.plot([],[],color=((1,0,0)),linewidth=2,label=ProLabels[1]);
ax2.plot([],[],color=((0,1,0)),linewidth=2,label=ProLabels[2]);
ax2.plot([],[],color=((0,0,1)),linewidth=2,label=ProLabels[3]);
#================StackPlots for DOS====================================
yAxis=pdos[max_index,0]
ax2.fill_between(TDOS,yAxis,D,color=(167/300, 216/300, 222/300),facecolor=(1, 1, 1),linewidth=0);
ax2.fill_between(blue_dos+green_dos+red_dos,yAxis,D,color=(0,0,1),linewidth=0); 
ax2.fill_between(green_dos+red_dos,yAxis,D,color=(0,1,0),linewidth=0);
ax2.fill_between(red_dos,yAxis,D,color=(1,0,0),linewidth=0);
ax2.set_ylim([yl,yh]);ax2.set_xlim([DOS_Limit[0],DOS_Limit[1]]);
ax2.set_yticks([]); ax2.set_xlabel('DOS'); ax2.set_xticks([(DOS_Limit[0]+DOS_Limit[1])/2,DOS_Limit[1]])
ax2.set_xticklabels([np.round((DOS_Limit[0]+DOS_Limit[1])/2,1),np.round(DOS_Limit[1],1)]);
gs.update(left=0.15,bottom=0.15,wspace=0.0, hspace=0.0) # set the spacing between axes.
leg=ax2.legend(fontsize='small',frameon=False,handletextpad=0.5,handlelength=1.5,columnspacing=1,ncol=5, bbox_to_anchor=(-7.2/3, 1), loc='lower left');
#===================Name it & Save===============================
ProLabels=[prolabel.replace("$","").replace("_","").replace("^","") for prolabel in ProLabels]; #Remove $ and _ characters in path
atom_index_range=','.join(str(ProIndices[0][i]+1) for i in range(np.shape(ProIndices[0])[0])); #creates a list of projected atoms
if(ProLabels[0]=='' or ProLabels[0]==' '): #check if this projection of whole composite.
    atom_index_range=str(ElemIndex[-1])
name=str(SYSTEM+'_'+ProLabels[0]+'['+atom_index_range+']'+'('+str(ProLabels[1])+')('+str(ProLabels[2])+')('+str(ProLabels[3])+')'+'_A'); #A for All,B for Bnads, D for DOS.
plt.savefig(str(name+'.svg'),transparent=True)
plt.savefig(str(name+'.pdf'),transparent=True)
plt.show()
'@
#Making a full dynamic projected file string for python use
$FileString=@"
$SystemVariables
$ImportPackages
$LoadFiles
$CollectData
$PlotData
"@  #No editing in this structure
#===========================Simple Plot variable file=====
$LoadingSimplePlotFiles=@"
text_x,text_y=textLocation;
#====================Loading Files===================================
KE=np.loadtxt('./Bands.txt')
data_dos=np.loadtxt('./$($parent)tDOS.txt')
"@
$SimplePlot=@'
K=KE[:,3]; E=KE[:,4:]-E_Fermi; #Seperate KPOINTS and Eigenvalues in memory
D=data_dos[:,0]-E_Fermi;TDOS=data_dos[:,1]; eGrid_DOS=int(np.shape(TDOS)[0]/ISPIN); #Energy grid mesh
yh=max(E_Limit);yl=min(E_Limit);        
#==================================================================
max_E=np.max(np.where(E[0,:] <=yh)); min_E=np.min(np.where(E[0,:] >=yl))
max_index=np.max(np.where(D[:eGrid_DOS] <=yh)); min_index=np.min(np.where(D[:eGrid_DOS] >=yl))
E=E[:,min_E:max_E+1]; D=D[min_index:max_index+1]  #Updated energy in E_limit upto max_E.
TDOS=TDOS[min_index:max_index+1]; #Updated total DOS
#=================Plotting============================
plt.figure(figsize=(3.4,2.5))
gs = GridSpec(1,2,width_ratios=(7,3))
ax1 = plt.subplot(gs[0])
ax2 = plt.subplot(gs[1])
ax2.tick_params(direction='in', length=2, width=0.2, colors='k', grid_color='k', grid_alpha=0.8)
def ax_settings(ax, x_ticks, x_labels, x_coord,y_coord,Element):
        ax.tick_params(direction='in', length=2, width=0.2, colors='k', grid_color='k', grid_alpha=0.8)
        ax.set_xticks(x_ticks)
        ax.set_xticklabels(x_labels)
        ax.set_xlim(K[0],K[-1])
        ax.set_ylim(yl,yh)
        ax.text(x_coord,y_coord,r"$\mathrm{%s}}$" % (SYSTEM),bbox=dict(edgecolor='white',facecolor='white', alpha=0.6),transform=ax.transAxes,color='red') 
        return None
#Lines at KPOINTS
kpts1=[[(K[ii],yl),(K[ii],yh)] for ii in tickIndices[1:-1]];
k_segments= LineCollection(kpts1,colors='k', linestyle='dashed',linewidths=(0.5),alpha=(0.6))
ax1.add_collection(k_segments)
ax1.plot([K[0],K[-1]],[0,0],'k',linewidth=0.3,linestyle='dashed',alpha=0.6) #Horizontal Line
#Full Data Plot
for i in range(np.shape(E)[1]):
    ax1.plot(K,E[:,i],color='b', linestyle='solid',linewidth=0.8)
ax1.autoscale_view()
ax1.set_ylabel(r'$E-E_F$(eV)')
ax1.set_xlabel('High Symmetry Path');
ticks=[K[ii] for ii in tickIndices];ticklabels[-1]=str(ticklabels[-1]) +"/"+ str(np.round(DOS_Limit[0],1))
ax_settings(ax1,ticks,ticklabels,text_x,text_y,ProLabels[0])
#================DOS====================================
ax2.plot(TDOS,D,color=((0,0,1,0.8)),linewidth=0.6);
ax2.set_ylim([yl,yh]);ax2.set_xlim([DOS_Limit[0],DOS_Limit[1]]);
ax2.set_yticks([]); ax2.set_xlabel('DOS'); ax2.set_xticks([(DOS_Limit[0]+DOS_Limit[1])/2,DOS_Limit[1]])
ax2.set_xticklabels([np.round((DOS_Limit[0]+DOS_Limit[1])/2,1),np.round(DOS_Limit[1],1)]);
gs.update(left=0.15,bottom=0.15,wspace=0.0, hspace=0.0) # set the spacing between axes.
#===================Name it & Save===============================
name=str(SYSTEM +'_A'); #A for All,B for Bands, D for DOS.
plt.savefig(str(name+'.svg'),transparent=True)
plt.savefig(str(name+'.pdf'),transparent=True)
plt.show()
'@ #Simple plot variable

#Making a full dynamic simple plot file string for python use
$SimpleFileString=@"
$SystemVariables
$ImportPackages
$LoadingSimplePlotFiles
$SimplePlot
"@  #No editing in this structur
#=============================Single BandsPlot=======================
$ProjectedBandsFile=@'
left,bottom,top,leg_x=0.15,0.15,0.85,0
text_x,text_y=textLocation;
if(WidthToColumnRatio <=0.7):
    mpl.rc('font', size=10)
    left,bottom,top,leg_x=0.3,0.2,0.8,-0.15
#====================Loading Files===================================
data=np.loadtxt('./Projection.txt')
KE=np.loadtxt('./Bands.txt')
K=KE[:,3]; E=KE[:,4:]-E_Fermi; #Seperate KPOINTS and Eigenvalues in memory
yh=max(E_Limit);yl=min(E_Limit);  
#============Calculation of ION(s)-Contribution=======
holder=np.zeros((NKPTS,NBANDS*nField_Projection))
for i in ProIndices[0]: #Indices for ion to claculate contribution of.
    new_mat=data[i*NKPTS:(i+1)*NKPTS,:]
    tot_pro=np.add(new_mat,holder)
    holder=new_mat
#=================================================================
#=========Seperating Orbital Projection for Bands and DOS==========
get_pro=np.zeros((NKPTS,nField_Projection)); #Defined matrix to pick Bands
def get_rgbProjection(NKPTS_by_nField_Matrix):
    mat_copy=copy.deepcopy(NKPTS_by_nField_Matrix) #copy matrix
    projection=np.zeros((np.shape(E))) #making a matrix to collect projections of one type
    for i in range(0,NBANDS*nField_Projection,nField_Projection):
        projection[:,int(i/nField_Projection)]=(tot_pro[:,i:i+nField_Projection]*mat_copy).sum(axis=1)         
    return projection          
#==================================================================
#Get (R,G.B) values from projection and Normlalize in plot range
maxEnergy=np.min(E,axis=0); minEnergy=np.max(E,axis=0); #Gets bands in visible energy limits.
max_E=np.max(np.where(maxEnergy <=yh)); min_E=np.min(np.where(minEnergy >=yl))
for i in ProIndices[1]: #projection in red color
    get_pro[:,i]=1;
    red=get_rgbProjection(get_pro)
    get_pro[:,:]=0; #Return back to zero
for j in ProIndices[2]: #projection in green color
    get_pro[:,j]=1;
    green=get_rgbProjection(get_pro)
    get_pro[:,:]=0; #Return back to zero
for k in ProIndices[3]: #projection in blue color
    get_pro[:,k]=1;
    blue=get_rgbProjection(get_pro)
    get_pro[:,:]=0; #Return back to zero
max_con=max(max(map(max,red[:,min_E:max_E])),max(map(max,green[:,min_E:max_E])),max(map(max,blue[:,min_E:max_E])))
red=red[:,min_E:max_E+1]/max_con;green=green[:,min_E:max_E+1]/max_con;blue=blue[:,min_E:max_E+1]/max_con #Values are ready in E_Limit
E=E[:,min_E:max_E+1]; #Updated energy in E_limit 
#===============Make Collections======================
E_List=[[[(K[i],E[i,j]),(K[i+1],E[i+1,j])]for i in range(NKPTS-1)]for j in range(np.shape(E)[1])];
rgb_List=[[(red[i:(i+2),j].sum()/2,green[i:(i+2),j].sum()/2,blue[i:(i+2),j].sum()/2,1) for i in range(NKPTS-1)] for j in range (np.shape(E)[1])];
lw_List=[[0.3+8*(red[i,j]+red[i+1,j]+green[i,j]+green[i+1,j]+blue[i,j]+blue[i+1,j])/6 \
 for i in range(NKPTS-1)] for j in range (np.shape(E)[1])]; # 0.3 as residual width
#=================Plotting============================
wd=WidthToColumnRatio; #sets width w.r.t atricle's column width
plt.figure(figsize=(wd*3.4,wd*3))
gs = GridSpec(1,1)
ax1 = plt.subplot(gs[0])
def ax_settings(ax, x_ticks, x_labels, x_coord,y_coord,Element):
        ax.tick_params(direction='in', length=2, width=0.2, colors='k', grid_color='k', grid_alpha=0.8)
        ax.set_xticks(x_ticks)
        ax.set_xticklabels(x_labels)
        ax.set_xlim(K[0],K[-1])
        ax.set_ylim(yl,yh)
        ax.text(x_coord,y_coord,r"$\mathrm{%s}^{\mathrm{%s}}$" % (SYSTEM, Element),bbox=dict(edgecolor='white',facecolor='white', alpha=0.7),transform=ax.transAxes,color='red') 
        return None
#Lines at KPOINTS
kpts1=[[(K[ii],yl),(K[ii],yh)] for ii in tickIndices[1:-1]];
k_segments= LineCollection(kpts1,colors='k', linestyle='dashed',linewidths=(0.5),alpha=(0.6))
ax1.add_collection(k_segments)
ax1.plot([K[0],K[-1]],[0,0],'k',linewidth=0.3,linestyle='dashed',alpha=0.6) #Horizontal Line
#Full Data Plot
for i in range(np.shape(E)[1]):
    line_segments = LineCollection(E_List[i],colors=rgb_List[i], linestyle='solid',linewidths=lw_List[i])
    ax1.add_collection(line_segments)
ax1.autoscale_view()
ax1.set_ylabel(r'$E-E_F$(eV)')
ticks=[K[ii] for ii in tickIndices];
ax_settings(ax1,ticks,ticklabels,text_x,text_y,ProLabels[0])
#=============Dummy Plots for Legend====================================
ax1.plot([],[],color=((1,0,0)),linewidth=2,label=ProLabels[1]);
ax1.plot([],[],color=((0,1,0)),linewidth=2,label=ProLabels[2]);
ax1.plot([],[],color=((0,0,1)),linewidth=2,label=ProLabels[3]);
gs.update(left=left,bottom=bottom,top=top,wspace=0.0, hspace=0.0) # set the spacing between axes.
leg=ax1.legend(fontsize='small',frameon=False,handletextpad=0.5,handlelength=1.5,columnspacing=1,ncol=5, bbox_to_anchor=(leg_x, 1), loc='lower left');
#===================Name it & Save===============================
ProLabels=[prolabel.replace("$","").replace("_","").replace("^","") for prolabel in ProLabels]; #Remove $ and _ characters in path
atom_index_range=','.join(str(ProIndices[0][i]+1) for i in range(np.shape(ProIndices[0])[0])); #creates a list of projected atoms
if(ProLabels[0]=='' or ProLabels[0]==' '): #check if this projection of whole composite.
    atom_index_range=str(ElemIndex[-1])
name=str(SYSTEM+'_'+ProLabels[0]+'['+atom_index_range+']'+'('+str(ProLabels[1])+')('+str(ProLabels[2])+')('+str(ProLabels[3])+')'+'_A'); #A for All,B for Bnads, D for DOS.
plt.savefig(str(name+'.svg'),transparent=True)
plt.savefig(str(name+'.pdf'),transparent=True)
plt.show()
'@

#Making a full dynamic projected bands plot file string for python use
$ProjectedBandsFileString=@"
$SystemVariables
$ImportPackages
$ProjectedBandsFile
"@  #No editing in this structur