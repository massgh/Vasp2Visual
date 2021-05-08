# All plots from vasprun.xml are here.
function Get-FigArgs {
    [CmdletBinding()]
        param (
            [Parameter()][switch]$sBands,
            [Parameter()][switch]$sDOS,
            [Parameter()][switch]$iRGB,
            [Parameter()][switch]$iDOS,
            [Parameter()][switch]$sColor,
            [Parameter()][switch]$sRGB
        )
    $out = $null
    if($sBands.IsPresent){
        [hashtable]$out=[ordered]@{skipk = "None";kseg_inds = "[]";elim = "[]";ktick_inds = "[]";ktick_vals = "[]";E_Fermi = "None";txt = "None";xytxt = "[0.05, 0.9]";ctxt = "'black'";interp_nk = "{}";}
    }
    if($sDOS.IsPresent){
        [hashtable]$out=[ordered]@{elim = "[]";include_dos = "'both'";elements = "[[0]]";orbs = "[[0]]";labels = "['s']";colormap = "'gist_rainbow'";tdos_color = "(0.8, 0.95, 0.8)";linewidth = "0.5";fill_area = "True";vertical = "False";E_Fermi = "None";
        txt = "None";xytxt = "[0.05, 0.85]";ctxt = "'black'";spin = "'both'";interp_nk = "{}";showlegend = "True";
        legend_kwargs = "{'ncol': 4, 'anchor': (0, 1), 'handletextpad': 0.5, 'handlelength': 1, 'fontsize': 'small', 'frameon':True}";}
    }
    if($iRGB.IsPresent){
        [hashtable]$out=[ordered]@{elements = "[[],[],[]]";orbs = "[[], [], []]"; labels = "['', '', '']";mode = "'markers'"; elim = "[]";E_Fermi = "None";skipk = "None";kseg_inds = "[]";max_width = "5";
        title = "None";ktick_inds = "[0, -1]";ktick_vals = "['Γ', 'M']";figsize = "None";interp_nk = "{}";}
    }
    if($iDOS.IsPresent){
        [hashtable]$out=[ordered]@{elim = "[]";elements = "[[0]]";orbs = "[[0]]";labels = "['s']";colormap = "'gist_rainbow'";tdos_color = "(0.5, 0.95, 0)";linewidth = "2";fill_area = "True";
        vertical = "False";E_Fermi = "None";figsize = "None";spin = "'both'";interp_nk = "{}";title = "None"}
    }
    if($sColor.IsPresent){
        [hashtable]$out=[ordered]@{skipk = "None";  kseg_inds = "[]";  elim = "[]";        elements = "[[0]]"; orbs = "[[0]]";     labels = "['s']";colormap = "'gist_rainbow'"; max_width = "2.5";  
        ktick_inds = "[0, -1]"; ktick_vals = "['$\\Gamma$', 'M']"; E_Fermi = "None"; showlegend = "True"; txt = "None"; xytxt = "[0.05, 0.85]"; 
        ctxt = "'black'"; spin = "'both'"; interp_nk = "{}";
        legend_kwargs = "{'ncol': 4, 'anchor': (0, 0.85), 'handletextpad': 0.5, 'handlelength': 1, 'fontsize': 'small', 'frameon': True}";
        }
    }
    if($sRGB.IsPresent){
        [hashtable]$out=[ordered]@{skipk = "None"; kseg_inds = "[]"; elim = "[]"; elements = "[[0], [], []]";   orbs = "[[0], [], []]"; labels = "['Elem0-s', '', '']"; max_width = "2.5"; ktick_inds = "[0, -1]"; ktick_vals = "['$\\Gamma$', 'M']";
        E_Fermi = "None";txt = "None";xytxt = "[0.05, 0.9]";ctxt = "'black'";uni_width = "False";interp_nk = "{}";spin = "'both'";scale_color = "True"; colorbar="True" ;
        }
    }
    $out
}

function New-Figure {
    [CmdletBinding(DefaultParameterSetName='MPL')]
    param (
       # Input Vasprun.xml
       [Parameter(ValueFromPipeline = $true)]$VasprunFile="./vasprun.xml",
       # Switches for Plots
       [Parameter(Position=1,ParameterSetName='MPL')][switch]$sBands,
       [Parameter(Position=1,ParameterSetName='MPL')][switch]$sDOS,
       [Parameter(Position=1,ParameterSetName='Plotly')][switch]$iRGB,
       [Parameter(Position=1,ParameterSetName='Plotly')][switch]$iDOS,
       [Parameter(Position=1,ParameterSetName='MPL')][switch]$sColor,
       [Parameter(Position=1,ParameterSetName='MPL')][switch]$sRGB,
       # FigArgs from Get-FigArgs
       [Parameter()][hashtable]$FigArgs,
       # Save HTML
       [Parameter(ParameterSetName='Plotly')]$SaveHTML,
       # Save HTML-Connected
       [Parameter(ParameterSetName='Plotly')]$SaveMinHTML, 
       # Save PDF
       [Parameter(ParameterSetName='MPL')]$SavePDF,
       # Save PNG
       [Parameter(ParameterSetName='MPL')]$SavePNG,
       # Save Python File
       [Parameter()]$SavePyFile

    )
    $VasprunFile = $VasprunFile.replace('\','/').replace('\\','/')
    $parentDir = Split-Path -Path $VasprunFile

    if($PSBoundParameters.ContainsKey('FigArgs')){
    $kwargs = $FigArgs.GetEnumerator()|ForEach-Object{"{0} = {1}" -f $_.key,$_.Value}
    $kwargs = "dict(`n" + "{0}" -f $($kwargs -join ",`n") + "`n)"
    }else{$kwargs='dict()'}

    # Process
    $command = 'splot_bands' # Default Command if No switch given.
    if($sBands.IsPresent){$command = 'splot_bands'}
    if($sDOS.IsPresent){$command   = 'splot_dos_lines'}
    if($iRGB.IsPresent){$command   = 'iplot_rgb_lines'}
    if($iDOS.IsPresent){$command   = 'iplot_dos_lines'}
    if($sColor.IsPresent){$command = 'splot_color_lines'}
    if($sRGB.IsPresent){$command   = 'splot_rgb_lines'}
    # Parameters Usage
    if($PSBoundParameters.ContainsKey('SaveHTML')){$save= "fig.write_html('{0}')" -f $SaveHTML}
    if($PSBoundParameters.ContainsKey('SaveMinHTML')){$save= "pp.plotly2html(fig, filename='{0}')" -f $SaveHTML}
    if($PSBoundParameters.ContainsKey('SavePDF')){$save= "pp._savefig('{0}',transparent=True)" -f $SavePDF}
    if($PSBoundParameters.ContainsKey('SavePNG')){$save= "pp._savefig('{0}',transparent=True,dpi =600)" -f $SavePNG}
    if($PSCmdlet.ParameterSetName -eq 'MPL'){$show = 'pp._show()'}Else{$show = 'fig.show()'} # Keep above save_options to work.
    $save_options = @('SaveHTML','SaveMinHTML','SavePDF','SavePNG')
    $save_options | ForEach-Object {if($PSBoundParameters.ContainsKey($_)){$show = '#' + $show}}
    
    $check_file = Join-Path -Path $parentDir -ChildPath 'SysInfo.py'
    if(Test-Path -Path $check_file){
    $load = "pp.load_export(path = '{0}')" -f $VasprunFile
    }else{$load = " '{0}' " -f $VasprunFile}  

    $init = "import pivotpy as pp`nfig = pp.{0}(path_evr = {1}, **kwargs)`n{2}`n{3}" -f $command,$load,$save,$show
    $init = "kwargs = {0}`n{1}" -f $kwargs,$init
    if($PSBoundParameters.ContainsKey('SavePyFile')){$init | Set-Content $SavePyFile}
    # Run it finally Using Default python on System preferably.
    if($null -ne (Get-Command python3* -ErrorAction SilentlyContinue)){
        Write-Host ("Running using {0}" -f (python3 -V)) -ForegroundColor Green
        $init | python3
    }elseif($null -ne (Get-Command python -ErrorAction SilentlyContinue)){
        Write-Host ("Running using {0}" -f (python -V)) -ForegroundColor Green
        $init | python
    }elseif($null -ne (Get-Command pytnon2* -ErrorAction SilentlyContinue)){
        Write-Host ("Required Python >= 3.6, but {0} found, try upgrading Python." -f (python2 -V)) -ForegroundColor Red
    }else{
        Write-Host "Python Installation not found. Copy code below and run yourself or use '-SavePyFile'." -ForegroundColor Red
        Write-Host $init -ForegroundColor Yellow
    }
}
Export-ModuleMember -Function 'Get-FigArgs'
Export-ModuleMember -Function 'New-Figure'
